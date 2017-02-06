# encoding: utf-8
require "socket"
require "securerandom"
require "fileutils"
require "zlib"
require "forwardable"

module LogStash
  module Outputs
    class Qingstor
      class TemporaryFileFactory
        FILE_MODE = "a"
        GZIP_ENCODING = "gzip"
        GZIP_EXTENSION = "log.gz"
        TXT_EXTENSION = "log"
        STRFTIME = "%Y-%m-%dT%H.%M"

        attr_accessor :counter, :tags, :prefix, :encoding, :tmpdir, :current

        def initialize(prefix, tags, encoding, tmpdir)
          @counter = 0
          @prefix = prefix
          @tags = tags
          @encoding = encoding
          @tmpdir = tmpdir
          @lock = Mutex.new 

          rotate!
        end 

        def rotate!
          @lock.synchronize {
            @current = new_file
            increment_counter
            @current 
          }
        end 

        private 
        def extension
          gzip? ? GZIP_ENCODING : TXT_EXTENSION
        end 
        
        def gzip?
          encoding == GZIP_ENCODING
        end 

        def increment_counter
          @counter += 1
        end 

        def current_time 
          Time.new.strftime(STRFTIME)
        end 

        def generate_name 
          filename = "ls.qingstor.#{SecureRandom.uuid}.#{current_time}"

          if tags.size > 0
            "#{filename}.tag_#{tags.join('.')}.part#{counter}.#{extension}"
          else 
            "#{filename}.part#{counter}.#{extension}"
          end 
        end 

        def new_file 
          uuid = SecureRandom.uuid 
          name = generate_name 
          path = ::File.join(@tmpdir, uuid)
          key = ::File.join(@prefix, name)

          FileUtils.mkdir_p(::File.join(path, @prefix))

          io = if gzip? 
                 IOWrappedGzip.new(::File.open(::File.join(path, key), FILE_MODE))
               else 
                 ::File.open(::File.join(path, key), FILE_MODE)
               end 

          TemporaryFile.new(key, io, path)
        end

        class IOWrappedGzip 
          extend Forwardable 

          def_delegators :@gzip_writer, :write, :close
          attr_accessor :file_io, :gzip_writer
        
          def initialize(file_io)
            @file_io = file_io
            @gzip_writer = Zlib::GzipWriter.open(file_io)
          end 

          def path 
            @gzip_writer.to_io.path 
          end 
          
          def size 
            @gzip_writer.flush 
            @gzip_writer.to_io.size 
          end 

          def fsync 
            @gzip_writer.to_io.fsync 
          end 
        end 
      end 
    end 
  end 
end 
