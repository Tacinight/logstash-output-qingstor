# encoding: utf-8

require 'logstash/devutils/rspec/spec_helper'
require 'logstash/outputs/qingstor/temporary_file'
require 'logstash/outputs/qingstor/rotation_policy'

describe LogStash::Outputs::Qingstor::RotationPolicy do
  let(:file_size) { 5 }
  let(:file_time) { 2 }

  shared_examples 'size rotation' do
    it 'raise error if file_size is no grater then 0' do
      expect { described_class.new('size', 0, 0) }
        .to raise_error(LogStash::ConfigurationError)
      expect { described_class.new('size', -1, 0) }
        .to raise_error(LogStash::ConfigurationError)
    end

    it "return true if the file has a bigger size value then 'file_size'" do
      file = double('file')
      allow(file).to receive(:ctime) { Time.now }
      allow(file).to receive(:empty?) { true }
      allow(file).to receive(:size) { 5 * 1024 * 1024 }
      expect(subject.rotate?(file)).to be_truthy
    end

    it 'return false if the file size is zero' do
      file = double('file')
      allow(file).to receive(:ctime) { Time.now }
      allow(file).to receive(:empty?) { true }
      allow(file).to receive(:size) { 0 }
      expect(subject.rotate?(file)).to be_falsey
    end
  end

  shared_examples 'time rotation' do
    it 'raise error if file_time is no grater then 0' do
      expect { described_class.new('time', 0, 0) }
        .to raise_error(LogStash::ConfigurationError)
      expect { described_class.new('time', 0, -1) }
        .to raise_error(LogStash::ConfigurationError)
    end

    it 'return false if the file is not old enough' do
      file = double('file')
      allow(file).to receive(:ctime) { Time.now }
      allow(file).to receive(:empty?) { false }
      allow(file).to receive(:size) { 2 * 1024 * 1024 }
      expect(subject.rotate?(file)).to be_falsey
    end

    it 'return false if the file is old enough with file size 0' do
      file = double('file')
      allow(file).to receive(:ctime) { Time.now - (file_time * 2 * 60) }
      allow(file).to receive(:empty?) { true }
      allow(file).to receive(:size) { 0 }
      expect(subject.rotate?(file)).to be_falsey
    end

    it 'return truth if the file is old enough and non-empty' do
      file = double('file')
      allow(file).to receive(:ctime) { Time.now - (file_time * 2 * 60) }
      allow(file).to receive(:empty?) { false }
      allow(file).to receive(:size) { 5 * 1024 * 1024 }
      expect(subject.rotate?(file)).to be_truthy
    end
  end

  context 'when time policy' do
    subject { described_class.new('time', file_size, file_time) }

    include_examples 'time rotation'

    it 'get suitable description of the class' do
      time = file_time * 60
      expect(subject.to_s).to eq({:policy=>"time", 
                                  :file_time=>time}.to_s)
    end
  end

  context 'when size policy' do
    subject { described_class.new('size', file_size, file_time) }

    include_examples 'size rotation'

    it 'get suitable description of the class' do
      size = file_size * 1024 * 1024
      expect(subject.to_s).to eq({:policy=>"size", 
                                  :file_size=>size}.to_s)
    end
  end

  context 'when size_and_time policy' do
    subject { described_class.new('size_and_time', file_size, file_time) }

    include_examples 'time rotation'
    include_examples 'size rotation'

    it 'get suitable description of the class' do
      size = file_size * 1024 * 1024
      time = file_time * 60
      expect(subject.to_s).to eq({:policy=>"sizeandtime", 
                                  :file_time=>time,
                                  :file_size=>size}.to_s)
    end
  end
end
