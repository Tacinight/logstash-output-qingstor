# encoding: utf-8
require "qingstor/sdk"
require "fileutils"

module LogStash
  module Outputs
    class Qingstor
      class QingstorValidator
        attr_reader :logger 

        def initialize(logger)
          @logger = logger
        end 

        def bucket_valid?(bucket)
          res = bucket.head
          case res[:status_code] 
          when 401
            raise LogStash::ConfigurationError, "Incorrect key id or access key."
          when 404
            raise LogStash::ConfigurationError, "Incorrect bucket/region name."
          end 
          true 
        end 

      end 
    end 
  end 
end 