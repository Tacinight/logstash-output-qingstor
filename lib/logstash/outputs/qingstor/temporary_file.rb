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

        def key=(key)
          @key = key
        end

        def delete!
          begin
            @fd.close
          rescue
            IOError
          end
          FileUtils.rm(path, :force => true)
        end

        def empty?
          size.zero?
        end

        def self.create_from_existing_file(file_path, tmp_folder)
          key_parts = Pathname.new(file_path).relative_path_from(tmp_folder)
                              .to_s.split(::File::SEPARATOR)
          TemporaryFile.new(key_parts.join('/'),
                            ::File.open(file_path, 'r'),
                            tmp_folder.to_s)
        end
      end
    end
  end
end
