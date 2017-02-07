# encoding: utf-8
require "logstash-core"
require "logstash/outputs/base"
require "logstash/namespace"
require "tmpdir"
require "qingstor/sdk"

class LogStash::Outputs::Qingstor < LogStash::Outputs::Base
  require "logstash/outputs/qingstor/temporary_file"
  require "logstash/outputs/qingstor/temporary_file_factory"
  require "logstash/outputs/qingstor/file_repository"
  require "logstash/outputs/qingstor/size_rotation_policy"
  require "logstash/outputs/qingstor/time_rotation_policy"
  require "logstash/outputs/qingstor/size_and_time_rotation_policy"
  require "logstash/outputs/qingstor/uploader"

  PERIODIC_CHECK_INTERVAL_IN_SECONDS = 15
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
  config :region, :validate => :string, :required => true

  # The prefix of filenames
  config :prefix, :validate => :string, :default => nil

  # Set the directory where logstash store the tmp files before 
  # sending it to qingstor, default directory in linux /tmp/logstash
  config :tmpdir, :validate => :string, :default => File.join(Dir.tmpdir, "logstash")

  # Define tags to append to the file on the qingstor bucket
  config :tags, :validate => :array, :default => []

  # Specify the content encoding. Supports ("gzip"), defaults to "none"
  config :encoding, :validate => ["gzip", "none"], :default => "none"

  # Define the strategy to use to decide when we need to rotate the file and push it to S3,
  # The default strategy is to check for both size and time, the first one to match will rotate the file.
  config :rotation_strategy, :validate => ["size_and_time", "size", "time"], :default => "size_and_time"

  config :size_file, :validate => :number, :default => 1024 * 1024 * 5
  config :time_file, :validate => :number, :default => 15 

  # Specify how many workers to use to upload the files to S3
  config :upload_workers_count, :validate => :number, :default => (Concurrent.processor_count * 0.5).ceil

  # Number of items we can keep in the local queue before uploading them
  config :upload_queue_size, :validate => :number, :default => 2 * (Concurrent.processor_count * 0.25).ceil

  public
  def register
    @file_repository = LogStash::Outputs::Qingstor::FileRepository.new(@tags, @encoding, @tmpdir)

    @rotation = rotation_strategy

    executor = Concurrent::ThreadPoolExecutor.new({ :min_threads => 1,
                                                    :max_threads => 2,
                                                    :max_queue => 1,
                                                    :fallback_policy => :caller_runs })
    @uploader = LogStash::Outputs::Qingstor::Uploader.new(get_bucket, @logger, executor)

    start_periodic_check if @rotation.needs_periodic?
  end # def register

  public
  def multi_receive_encoded(events_and_encoded)
    prefix_written_to = Set.new

    events_and_encoded.each do |event, encoded|
      #prefix_key = normalized_key(event.sprintf(@prefix))
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
      LogStash::Outputs::Qingstor::SizeRotationPolicy.new(@size_file)
    when "time"
      LogStash::Outputs::Qingstor::TimeRotationPolicy.new(@time_file)
    when "size_and_time"
      LogStash::Outputs::Qingstor::SizeAndTimeRotationPolicy.new(@size_file, @time_file)
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
    @uploader.upload_async(file,
                          :on_complete => method(:clean_temporary_file),
                          :upload_options => upload_options)
  end 

  def get_bucket
    @qs_config = QingStor::SDK::Config.init @access_key_id, @secret_access_key
    @qs_service = QingStor::SDK::Service.new @qs_config
    @qs_bucket = @qs_service.bucket @bucket, @region
  end 

  def close 
    stop_periodic_check if @rotation.needs_periodic?

    @logger.debug("uploading current workspace")
    @file_repository.each_files do |file|
      upload_file(file)
    end 

    @file_repository.shutdown

    @uploader.stop 
    # crash_uploader.stop if @restore
  end 

  def upload_options
    {
      :content_encoding => @encoding == "gzip" ? "gzip" : nil 
    }
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

end # class LogStash::Outputs::Qingstor