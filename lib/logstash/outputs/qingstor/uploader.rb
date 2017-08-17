# encoding: utf-8

require 'logstash/outputs/qingstor'
require 'qingstor/sdk'
require 'concurrent'
require 'digest/md5'
require 'base64'

module LogStash
  module Outputs
    class Qingstor
      class Uploader
        TIME_BEFORE_RETRYING_SECONDS = 1
        DEFAULT_THREADPOOL = Concurrent::ThreadPoolExecutor.new(
          :min_thread => 1,
          :max_thread => 8,
          :max_queue => 1,
          :fallback_policy => :caller_runs
        )

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

          file_md5 = Digest::MD5.file(file.path).to_s

          upload_headers = {
            'content_md5' => file_md5,
            'body' => ::File.read(file.path)
          }

          unless upload_options[:server_side_encryption_algorithm].nil?
            base64_key = Base64.strict_encode64(upload_options[:customer_key])
            key_md5 = Digest::MD5.hexdigest(upload_options[:customer_key])
            base64_key_md5 = Base64.strict_encode64(key_md5)
            upload_headers.merge!(
              'x_qs_encryption_customer_algorithm' =>
                upload_options[:server_side_encryption_algorithm],
              'x_qs_encryption_customer_key' => base64_key,
              'x_qs_encryption_customer_key_md5' => base64_key_md5
            )
          end
          @logger.debug('uploading file', :file => file.key)
          bucket.put_object(file.key, upload_headers)

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
