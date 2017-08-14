# encoding: utf-8

require 'logstash/devutils/rspec/spec_helper'
require 'logstash/outputs/qingstor/temporary_file'
require 'logstash/outputs/qingstor/rotation_policy'

describe LogStash::Outputs::Qingstor::RotationPolicy do
  let(:size_file) { 1024 * 2 }
  let(:time_file) { 2 }
  let(:name) { 'foobar' }
  let(:tmp_file) { Stud::Temporary.file }
  let(:tmp_dir) { tmp_file.path }
  let(:file) do
    LogStash::Outputs::Qingstor::TemporaryFile.new(name, tmp_file, tmp_dir)
  end
  let(:content) { 'May the code be with you' * 100 }

  context 'when size_and_time policy' do
    subject { described_class.new('size_and_time', size_file, time_file) }

    it 'raise error if time_file is no grater then 0' do
      expect { described_class.new('size_and_time', 0, 0) }
        .to raise_error(LogStash::ConfigurationError)
      expect { described_class.new('size_and_time', -1, 0) }
        .to raise_error(LogStash::ConfigurationError)
      expect { described_class.new('size_and_time', 0, -1) }
        .to raise_error(LogStash::ConfigurationError)
      expect { described_class.new('size_and_time', -1, -1) }
        .to raise_error(LogStash::ConfigurationError)
    end

    it 'return false if the file is not old enough' do
      expect(subject.rotate?(file)).to be_falsey
    end

    it 'return false if the file is old enough with file size 0' do
      allow(file)
        .to receive(:ctime).and_return(Time.now - (time_file * 2 * 60))
      expect(subject.rotate?(file)).to be_falsey
    end

    it 'return truth if the file is old enough and non-empty' do
      file.write(content)
      file.fsync
      allow(file)
        .to receive(:ctime).and_return(Time.now - (time_file * 2 * 60))
      expect(subject.rotate?(file)).to be_truthy
    end
  end

  context 'when size policy' do
    subject { described_class.new('size', size_file, time_file) }

    it 'raise error if size_file is no grater then 0' do
      expect { described_class.new('size', 0, 0) }
        .to raise_error(LogStash::ConfigurationError)
      expect { described_class.new('size', -1, 0) }
        .to raise_error(LogStash::ConfigurationError)
    end

    it "return true if the file has a bigger size value then 'size_file'" do
      file.write(content)
      file.fsync
      expect(subject.rotate?(file)).to be_truthy
    end
  end

  context 'when time policy' do
    subject { described_class.new('time', size_file, time_file) }

    it 'raise error if time_file is no grater then 0' do
      expect { described_class.new('time', 0, 0) }
        .to raise_error(LogStash::ConfigurationError)
      expect { described_class.new('time', 0, -1) }
        .to raise_error(LogStash::ConfigurationError)
    end

    it 'return false if the file is not old enough' do
      expect(subject.rotate?(file)).to be_falsey
    end

    it 'return false if the file is old enough with file size 0' do
      allow(file)
        .to receive(:ctime).and_return(Time.now - (time_file * 2 * 60))
      expect(subject.rotate?(file)).to be_falsey
    end

    it 'return truth if the file is old enough and non-empty' do
      file.write(content)
      file.fsync
      allow(file)
       .to receive(:ctime).and_return(Time.now - (time_file * 2 * 60))
      expect(subject.rotate?(file)).to be_truthy
    end
  end
end
