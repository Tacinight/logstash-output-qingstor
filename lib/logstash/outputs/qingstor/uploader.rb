# encoding: utf-8
require "qingstor/sdk"
require "concurrent"

module LogStash
  module Outputs
    class Qingstor
      class Uploader 
        TIME_BEFORE_RETRYING_SECONDS = 1
        DEFAULT_THREADPOOL = Concurrent::ThreadPoolExecutor.new({ :min_thread => 1,
                                                                  :max_thread => 8,
                                                                  :max_queue => 1,
                                                                  :fallback_policy => :caller_runs
                                                                })
        attr_reader :bucket, :upload_options, :logger 

        def initialize(bucket, logger, threadpool = DEFAULT_THREADPOOL)
          @bucket = bucket
          @logger = logger
          @workers_pool = threadpool
        end 

        def upload_async(file, options = {})
          @workers_pool.post do
            upload(file, options)
          end 
        end 

        def upload(file, options = {})
          upload_options = options.fetch(:upload_options, {})

          md5_string = Digest::MD5.file(file.path).to_s
          bucket.put_object( file.key, { 
                            'content_md5' => md5_string,
                            'body' => ::File.open(file.path)})

          options[:on_complete].call(file) unless options[:on_complete].nil?
        end 

        def stop 
          @workers_pool.shutdown
          @workers_pool.wait_for_termination(nil)
        end 
      end 
    end 
  end 
end 
          