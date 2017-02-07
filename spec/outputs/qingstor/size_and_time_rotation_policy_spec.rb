# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/qingstor/temporary_file"
require "logstash/outputs/qingstor/size_and_time_rotation_policy"

describe LogStash::Outputs::Qingstor::SizeAndTimeRotationPolicy do
  let(:size_file) { 1024 * 2 }
  let(:time_file) { 2 }
  let(:name) { "foobar" }
  let(:tmp_file) { Stud::Temporary.file }
  let(:tmp_dir) { tmp_file.path }
  let(:file) { LogStash::Outputs::Qingstor::TemporaryFile.new(name, tmp_file, tmp_dir) }
  let(:content) { "May the code be with you" * 100 }
  subject { described_class.new(size_file, time_file) }

  it "raise error if time_file is no grater then 0" do 
    expect{ described_class.new(0, 0) }.to raise_error(LogStash::ConfigurationError)
    expect{ described_class.new(-1, 0) }.to raise_error(LogStash::ConfigurationError)
    expect{ described_class.new(0, -1) }.to raise_error(LogStash::ConfigurationError)
    expect{ described_class.new(-1, -1) }.to raise_error(LogStash::ConfigurationError)
  
  end 

  it "return false if the file is not old enough" do 
    expect(subject.rotate?(file)).to be_falsey
  end

  it "return false if the file is old enough with file size 0" do
    allow(file).to receive(:ctime).and_return(Time.now - (time_file * 2 * 60))
    expect(subject.rotate?(file)).to be_falsey
  end

  it "return truth if the file is old enough and non-empty" do 
    file.write(content)
    file.fsync
    allow(file).to receive(:ctime).and_return(Time.now - (time_file * 2 * 60))
    expect(subject.rotate?(file)).to be_truthy
  end
end 