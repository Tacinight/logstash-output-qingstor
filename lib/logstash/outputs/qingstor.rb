# encoding: utf-8
require "logstash-core"
require "logstash/outputs/base"
require "logstash/namespace"
require "tmpdir"
require "qingstor/sdk"
require "concurrent"

class LogStash::Outputs::Qingstor < LogStash::Outputs::Base
  require "logstash/outputs/qingstor/temporary_file"
  require "logstash/outputs/qingstor/temporary_file_factory"
  require "logstash/outputs/qingstor/file_repository"
  require "logstash/outputs/qingstor/size_rotation_policy"
  require "logstash/outputs/qingstor/time_rotation_policy"
  require "logstash/outputs/qingstor/size_and_time_rotation_policy"
  require "logstash/outputs/qingstor/uploader"
  require "logstash/outputs/qingstor/qingstor_validator"

  PERIODIC_CHECK_INTERVAL_IN_SECONDS = 15
  CRASH_RECOVERY_THREADPOOL = Concurrent::ThreadPoolExecutor.new({
                                                                  :min_threads => 1,
                                                                  :max_threads => 2,
                                                                  :fallback_policy => :caller_runs
                                                                })
  config_name "qingstor"

  # When configured as :single a single instance of the Output will be shared among the
  # pipeline worker threads. Access to the `#multi_receive/#multi_receive_encoded/#receive` method will be synchronized
  # i.e. only one thread will be active at a time making threadsafety much simpler.
  #
  # You can set this to :shared if your output is threadsafe. This will maximize
  # concurrency but you will need to make appropriate uses of mutexes in `#multi_receive/#receive`.
  #
  # Only the `#multi_receive/#multi_receive_encoded` methods need to actually be threadsafe, the other methods
  # will only be executed in a single thread
  concurrency :shared

  # The key id to access your QingStor
  config :access_key_id, :validate => :string, :required => true

  # The key to access your QingStor
  config :secret_access_key, :validate => :string, :required => true

  # The name of the qingstor bucket
  config :bucket, :validate => :string, :required => true

  # The region of the QingStor bucket
  config :region, :validate => ["pek3a", "sh1a"], :default => "pek3a"

  # The prefix of filenames which will work as directory in qingstor 
  config :prefix, :validate => :string, :default => ''

  # Set the directory where logstash store the tmp files before 
  # sending it to qingstor, default directory in linux /tmp/logstash2qingstor
  config :tmpdir, :validate => :string, :default => File.join(Dir.tmpdir, "logstash2qingstor")

  # Define tags to append to the file on the qingstor bucket
  config :tags, :validate => :array, :default => []

  # Specify the content encoding. Supports ("gzip"), defaults to "none"
  config :encoding, :validate => ["gzip", "none"], :default => "none"

  # Define the strategy to use to decide when we need to rotate the file and push it to S3,
  # The default strategy is to check for both size and time, the first one to match will rotate the file.
  config :rotation_strategy, :validate => ["size_and_time", "size", "time"], :default => "size_and_time"

  # Define the size requirement for each file to upload to qingstor. In byte.
  config :size_file, :validate => :number, :default => 1024 * 1024 * 5

  # Define the time interval for each file to upload to qingstor. In minutes.
  config :time_file, :validate => :number, :default => 15 

  # Specify maximum number of workers to use to upload the files to Qingstor
  config :upload_workers_count, :validate => :number, :default => (Concurrent.processor_count * 0.5).ceil

  # Number of items we can keep in the local queue before uploading them
  config :upload_queue_size, :validate => :number, :default => 2 * (Concurrent.processor_count * 0.25).ceil

  # Specifies what type of encryption to use when SSE is enabled.
  config :server_side_encryption_algorithm, :validate => ["AES256", "none"], :default => "none"

  # Specifies the encryption customer key that would be used in server side   
  config :customer_key, :validate => :string

  # Specifies if set to true, it would upload existing file in targeting folder at the beginning.
  config :restore, :validate => :boolean, :default => false  

  public
  def register
    QingstorValidator.prefix_valid?(@prefix) unless @prefix.nil?

    if !directory_valid?(@tmpdir)
      raise LogStash::ConfigurationError, "Logstash must have the permissions to write to the temporary directory: #{@tmpdir}"
    end
    
    @file_repository = FileRepository.new(@tags, @encoding, @tmpdir)

    @rotation = rotation_strategy

    executor = Concurrent::ThreadPoolExecutor.new({ 
      :min_threads => 1,
      :max_threads => @upload_workers_count,
      :max_queue => @upload_queue_size,
      :fallback_policy => :caller_runs 
    })

    @qs_bucket = get_bucket
    QingstorValidator.bucket_valid?(@qs_bucket)

    @uploader = Uploader.new(@qs_bucket, @logger, executor)

    start_periodic_check if @rotation.needs_periodic?

    restore_from_crash if @restore 
  end # def register

  public
  def multi_receive_encoded(events_and_encoded)
    prefix_written_to = Set.new

    events_and_encoded.each do |event, encoded|
      prefix_key = event.sprintf(@prefix)
      prefix_written_to << prefix_key

      begin
        @file_repository.get_file(prefix_key) { |file| file.write(encoded) }
      rescue Errno::ENOSPC => e
        @logger.error("QingStor: Nospace left in temporary directory", :tmpdir => @tmpdir)
        raise e 
      end 
    end # end of each method  

    # check the file after file writing 
    # Groups IO calls to optimize fstat checks 
    rotate_if_needed(prefix_written_to)
  end  # def multi_receive_encoded
  
  def rotation_strategy 
    case @rotation_strategy
    when "size"
      SizeRotationPolicy.new(@size_file)
    when "time"
      TimeRotationPolicy.new(@time_file)
    when "size_and_time"
      SizeAndTimeRotationPolicy.new(@size_file, @time_file)
    end 
  end 

  def rotate_if_needed(prefixs)
    prefixs.each do |prefix|
      @file_repository.get_factory(prefix) do |factory|
        tmp_file = factory.current

        if @rotation.rotate?(tmp_file)
          @logger.debug("Rotate file", 
                        :strategy => tmp_file.key,
                        :path => tmp_file.path)
          upload_file(tmp_file)
          factory.rotate!
        end 
      end 
    end 
  end # def rotate_if_needed

  def upload_file(file)
    @logger.debug("Add file to uploading queue", :key => file.key)
    file.close 
    @logger.debug("upload options", :upload_options => upload_options)
    @uploader.upload_async(file,
                          :on_complete => method(:clean_temporary_file),
                          :upload_options => upload_options)
  end 

  def get_bucket
    @qs_config = QingStor::SDK::Config.init @access_key_id, @secret_access_key
    @qs_service = QingStor::SDK::Service.new @qs_config
    @qs_service.bucket @bucket, @region
  end 

  def close 
    stop_periodic_check if @rotation.needs_periodic?

    @logger.debug("uploading current workspace")
    @file_repository.each_files do |file|
      upload_file(file)
    end 

    @file_repository.shutdown

    @uploader.stop 

    @crash_uploader.stop if @restore
  end 

  def upload_options
    options = {
      :content_encoding => @encoding == "gzip" ? "gzip" : nil 
    }

    if  @server_side_encryption_algorithm == "AES256" && !@customer_key.nil?
      options.merge!({
        :server_side_encryption_algorithm => @server_side_encryption_algorithm,
        :customer_key => @customer_key
      })
    end 
    
    options 
  end 

  def clean_temporary_file(file)
    @logger.debug("Removing temporary file", :file => file.path)
    file.delete!
  end 

  def start_periodic_check
    @logger.debug("Start periodic rotation check")

    @periodic_check = Concurrent::TimerTask.new(:execution_interval => PERIODIC_CHECK_INTERVAL_IN_SECONDS) do
      @logger.debug("Periodic check for stale files")

      rotate_if_needed(@file_repository.keys)
    end

    @periodic_check.execute 
  end 

  def stop_periodic_check 
    @periodic_check.shutdown 
  end 

  def directory_valid?(path)
    begin 
      FileUtils.mkdir_p(path) unless Dir.exist?(path)
      ::File.writable?(path)
    rescue 
      false 
    end 
  end 

  def restore_from_crash 
    @crash_uploader = Uploader.new(@qs_bucket, @logger, CRASH_RECOVERY_THREADPOOL)

    temp_folder_path = Pathname.new(@tmpdir)
    Dir.glob(::File.join(@tmpdir, "**/*"))
      .select { |file| ::File.file?(file) }
      .each do |file| 
      temp_file = TemporaryFile.create_from_existing_file(file, temp_folder_path)
      @logger.debug("Recoving from crash and uploading", :file => temp_file.path)
      @crash_uploader.upload_async(temp_file, :on_complete => method(:clean_temporary_file),
                                              :upload_options => upload_options)
    end 
  end 
end # class LogStash::Outputs::Qingstor