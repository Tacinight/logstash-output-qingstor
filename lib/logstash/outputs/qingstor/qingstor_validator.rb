# encoding: utf-8
require "qingstor/sdk"
require "fileutils"

module LogStash
  module Outputs
    class Qingstor
      class QingstorValidator

        def self.bucket_valid?(bucket)
          res = bucket.head
          case res[:status_code] 
          when 401
            raise LogStash::ConfigurationError, "Incorrect key id or access key."
          when 404
            raise LogStash::ConfigurationError, "Incorrect bucket/region name."
          end 
          true 
        end 

        def self.prefix_valid?(prefix)
          if prefix.start_with?("/") || prefix.length >= 1024
            raise LogStash::ConfigurationError, "Prefix must not start with '/' with length less than 1024 "
          end 
          true
        end 
      end 
    end 
  end 
end 