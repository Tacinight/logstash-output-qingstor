# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "tmpdir"

class LogStash::Outputs::Qinstor < LogStash::Outputs::Base
  config_name "qinstor"

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

  # Define tags to append to the file on the qinstor bucket
  config :tags, :validate => :array, default => []

  # Specify the content encoding. Supports ("gzip"), defaults to "none"
  config :encoding, :validate => ["gzip", "none"], default => "none"

  # Define the strategy to use to decide when we need to rotate the file and push it to S3,
  # The default strategy is to check for both size and time, the first one to match will rotate the file.
  config :rotation_strategy, :validate => ["size_and_time", "size", "time"], :default => "size_and_time"

  public
  def register
    require "logstash/outputs/qingstor/temporary_file"
    require "logstash/outputs/qingstor/temporary_file_factory"
    require "logstash/outputs/qingstor/file_repository"

    @file_repository = FileRepository.new(@tags, @encoding, @tmpdir)

    @rotation = rotation_strategy
  end # def register

  public
  def multi_receive_encoded(events_and_encoded)
    prefix_written_to = Set.new

    events_and_encoded.each do |event, encoded|
      prefix_key = normalized_key(event.sprintf(@prefix))
      prefix_written_to << prefix_key

      begin
        @file_repository.get_file(prefix_key) { |file| file.write(encoded) }
      rescue Errno::ENOSPC => e
        @logger.error("QingStor: Nospace left in temporary directory", :tmpdir => @tmpdir)
        raise e 
      end 
    end # end of each method  
  end  # def multi_receive_encoded
  
  def rotation_strategy 
    case @rotation_strategy
    when "size"
      SizeRotationPolicy.new(size_file)
    when "time"
      TimeRotationPolicy.new(time_file)
    when "size_and_time"
      SizeAndTimeRatationPolicy.new(size_and_time)
    end 
  end 
end # class LogStash::Outputs::Qinstor
