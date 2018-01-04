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
        require 'logstash/outputs/qingstor/multipart_uploader'

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
          upload_headers = process_encrypt_options(upload_options)

          if file.size > 50 * 1024 * 1024
            @logger.debug('multipart uploading file', :file => file.key)
            multipart_uploader = MultipartUploader.new(@bucket, @logger, file, upload_headers)
            multipart_uploader.upload
          else
            upload_headers['content_md5'] = Digest::MD5.file(file.path).to_s
            upload_headers['body'] = ::File.read(file.path)
            @logger.debug('uploading file', :file => file.key)
            @bucket.put_object(file.key, upload_headers)
          end

          options[:on_complete].call(file) unless options[:on_complete].nil?
        end

        def process_encrypt_options(upload_options)
          res = {}

          unless upload_options[:server_side_encryption_algorithm].nil?
            base64_key = Base64.strict_encode64(upload_options[:customer_key])
            key_md5 = Digest::MD5.hexdigest(upload_options[:customer_key])
            base64_key_md5 = Base64.strict_encode64(key_md5)
            res.merge!(
              'x_qs_encryption_customer_algorithm' =>
                upload_options[:server_side_encryption_algorithm],
              'x_qs_encryption_customer_key' => base64_key,
              'x_qs_encryption_customer_key_md5' => base64_key_md5
            )
          end

          res
        end

        def stop
          @workers_pool.shutdown
          @workers_pool.wait_for_termination(nil)
        end
      end
    end
  end
end
