# encoding: utf-8

require 'logstash/outputs/qingstor'

module LogStash
  module Outputs
    class Qingstor
      class RotationPolicy
        class Policy
          def to_s
            name
          end

          def name
            self.class.name.split('::').last.downcase
          end

          def needs_periodic?
            true
          end

          def positive_check(*arg)
            arg.each do |x|
              raise(LogStash::ConfigurationError,
                    "#{name} policy needs positive arguments") if x <= 0
            end
          end
        end

        class Time < Policy
          def initialize(_, file_time)
            @file_time = file_time
            positive_check(@file_time)
          end

          def rotate?(file)
            !file.empty? && (::Time.now - file.ctime) >= @file_time
          end
        end

        class Size < Policy
          def initialize(file_size, _)
            @file_size = file_size
            positive_check(@file_size)
          end

          def rotate?(file)
            file.size >= @file_size
          end

          def needs_periodic?; false; end
        end

        class SizeAndTime < Policy
          def initialize(file_size, file_time)
            @file_size, @file_time = file_size, file_time
            positive_check(file_size, file_time)
          end

          def rotate?(file)
            (!file.empty? && (::Time.now - file.ctime) >= @file_time) ||
              (file.size >= @file_size)
          end
        end

        def Policy(policy, file_size, file_time)
          case policy
          when Policy then policy
          else
            self.class.const_get(policy.to_s.split('_').map(&:capitalize).join)
                .new(file_size, file_time)
          end
        end

        def initialize(policy, file_size, file_time)
          @policy = Policy(policy, to_bytes(file_size), to_seconds(file_time))
        end

        def to_seconds(file_time)
          file_time * 60
        end

        def to_bytes(file_size)
          file_size * 1024 * 1024
        end

        def rotate?(file)
          @policy.rotate?(file)
        end

        def needs_periodic?
          @policy.needs_periodic?
        end

        def to_s
          @policy.to_s
        end
      end
    end
  end
end
