# encoding: utf-8

require 'logstash/outputs/qingstor'
require 'thread'
require 'forwardable'
require 'fileutils'
require 'pathname'

module LogStash
  module Outputs
    class Qingstor
      class TemporaryFile
        extend Forwardable

        def_delegators :@fd, :path, :write, :close, :fsync

        attr_reader :fd

        def initialize(key, fd, tmp_path)
          @key = key
          @fd = fd
          @tmp_path = tmp_path
          @created_at = Time.now
        end

        def ctime
          @created_at
        end

        attr_reader :tmp_path

        def size
          @fd.size
        rescue IOError
          ::File.size(path)
        end

        def key
          @key.gsub(/^\//, '')
        end

        def delete!
          begin
            @fd.close
          rescue
            IOError
          end
          FileUtils.rm_r(@tmp_path, :secure => true)
        end

        def empty?
          size.zero?
        end

        def self.create_from_existing_file(file_path, tmp_folder)
          key_parts = Pathname.new(file_path).relative_path_from(tmp_folder)
                              .to_s.split(::File::SEPARATOR)
          TemporaryFile.new(key_parts.slice(1, key_parts.size).join('/'),
                            ::File.open(file_path, 'r'),
                            ::File.join(tmp_folder, key_parts.slice(0, 1)))
        end
      end
    end
  end
end
