# encoding: utf-8

require 'logstash/outputs/qingstor'

module LogStash
  module Outputs
    class Qingstor
      class Uploader
        class MultipartUploader
          attr_reader :bucket, :logger
          attr_accessor :upload_headers
        
          # According to QingStor API doc, the minimal part size is 4MB.
          # the maximal part size is 1GB.
          # Here the minimal size would never be used and the maximal part size is 50MB.
          # Overlarge file size would consume java heap space and throw Exceptions.
          MINIMAL_PART_SIZE = 4 * 1024 * 1024
          MAXIMAL_PART_SIZE = 50 * 1024 * 1024
          
          def initialize(bucket, logger, object, upload_headers)
            @bucket = bucket
            @logger = logger
            @object = object
            @upload_headers = upload_headers
          end
        
          def upload
            initiate_multipart_upload
            segment_size = calculate_segment
            upload_multipart(segment_size)
          end
        
          def initiate_multipart_upload
            res = @bucket.initiate_multipart_upload(@object.key, @upload_headers)
            @upload_headers['upload_id'] = res.fetch(:upload_id) do 
              raise(QingStor::Error, :error_msg => res)
            end
            @logger.debug('initiated upload id', :file => @object.key, 
                                                 :upload_id => res[:upload_id])
            res[:upload_id]
          end
        
          def upload_multipart(part_number = 0, segment_size)
            ::File.open(@object.path) do |f|
              f.seek(part_number * segment_size) if part_number != 0
              while data = f.read(segment_size)
                content_md5 = Digest::MD5.hexdigest(data)
                @upload_headers['body'] = data
                @upload_headers['content_length'] = segment_size
                @upload_headers['content_md5'] = content_md5
                @upload_headers['part_number'] = part_number
                @logger.debug('multipart uploading: ',
                              :file => @object.key,
                              :part_number => part_number)
                @bucket.upload_multipart(@object.key, @upload_headers)
                part_number += 1
              end
            end
            
            complete_multipart_upload(part_number - 1)
          end 
        
          def complete_multipart_upload(last_part_number)
            object_parts = (0..last_part_number).to_a.map {|x| {'part_number' => x}}
            @upload_headers['object_parts'] = object_parts
            res = @bucket.complete_multipart_upload(@object.key, @upload_headers)
            @logger.debug('multipart uploading completed', :file => @object.key)
          end 
        
          def calculate_segment
            segment_size = @object.size
            
            while segment_size >= MAXIMAL_PART_SIZE
              segment_size /= 2.0
              segment_size = segment_size.ceil
            end
        
            segment_size
          end
        
          def resume_multipart_upload(upload_id)
            @logger.debug('resume multipart uploading', :file => @object.key,
                                                        :upload_id => upload_id)
            @upload_headers['upload_id'] = upload_id
            res = @bucket.list_multipart(@object.key, upload_headers)
            segment_size = res[:object_parts][0][:size]
            part_number = res[:object_parts].count
            upload_multipart(part_number, segment_size)
          end
        end
      end
    end
  end
end