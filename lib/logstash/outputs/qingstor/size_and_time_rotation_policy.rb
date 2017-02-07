# encoding: utf-8
require "logstash/outputs/qingstor/size_rotation_policy"
require "logstash/outputs/qingstor/time_rotation_policy"

module LogStash 
  module Outputs 
    class Qingstor
      class SizeAndTimeRotationPolicy
        def initialize(size_file, time_file)
          @size_strategy = SizeRotationPolicy.new(size_file)
          @time_strategy = TimeRotationPolicy.new(time_file)
        end 

        def rotate?(file)
          @size_strategy.rotate?(file) || @time_strategy.rotate?(file)
        end 

        def needs_periodic?
          true
        end 
      end 
    end 
  end 
end 