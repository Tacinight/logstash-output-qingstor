# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/qingstor/temporary_file"
require "logstash/outputs/qingstor/size_rotation_policy"

describe LogStash::Outputs::Qingstor::SizeRotationPolicy do
  let(:size_file) { 1024 * 2 }
  let(:name) { "foobar" }
  let(:tmp_file) { Stud::Temporary.file }
  let(:tmp_dir) { tmp_file.path }
  let(:file) { LogStash::Outputs::Qingstor::TemporaryFile.new(name, tmp_file, tmp_dir) }
  let(:content) { "May the code be with you" * 100 }
  subject { described_class.new(size_file) }

  it "raise error if size_file is no grater then 0" do 
    expect{described_class.new(0)}.to raise_error(LogStash::ConfigurationError)
    expect{described_class.new(-1)}.to raise_error(LogStash::ConfigurationError)
  end 

  it "return true if the file has a bigger size value then 'size_file'" do 
    file.write(content)
    file.fsync
    expect(subject.rotate?(file)).to be_truthy
  end
end 