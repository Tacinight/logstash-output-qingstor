# encoding: utf-8

require 'logstash/outputs/qingstor'

module LogStash
  module Outputs
    class Qingstor
      class RotationPolicy
        def initialize(policy, file_size, file_time)
          @policy = policy
          case policy
          when 'time'
            init_time(file_time)
          when 'size'
            init_size(file_size)
          when 'size_and_time'
            init_size(file_size)
            init_time(file_time)
          end
        end

        def init_size(file_size)
          if file_size <= 0
            raise LogStash::ConfigurationError, "'file_size' need to "\
              + 'be greater than 0'
          end
          @file_size = file_size
        end

        def init_time(file_time)
          if file_time <= 0
            raise LogStash::ConfigurationError, "'file_time' need to "\
              + 'be greater than 0'
          end
          @file_time = file_time * 60
        end

        def rotate?(file)
          case @policy
          when 'time'
            time_rotate?(file)
          when 'size'
            size_rotate?(file)
          when 'size_and_time'
            size_and_time_rotate?(file)
          end
        end

        def size_and_time_rotate?(file)
          size_rotate?(file) || time_rotate?(file)
        end

        def size_rotate?(file)
          file.size >= @file_size
        end

        def time_rotate?(file)
          !file.empty? && (Time.now - file.ctime) >= @file_time
        end

        def needs_periodic?
          case @policy
          when 'time' then
            true
          when 'size_and_time' then
            true
          else
            false
          end
        end

        def to_s
          "#{@policy} #{@file_time} #{@file_size}"
        end
      end
    end
  end
end
