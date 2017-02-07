# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/qingstor/temporary_file"
require "logstash/outputs/qingstor/temporary_file_factory"
require "fileutils"
require "tmpdir"

describe LogStash::Outputs::Qingstor::TemporaryFileFactory do
  let(:prefix) { "lg2qs" }
  let(:tags) { ["tags1", "tag2"] }
  let(:encoding) { "none" }
  let(:tmpdir) { File.join(Dir.tmpdir, "logstash-qs") }
  subject { described_class.new(prefix, tags, encoding, tmpdir) }

  it "create the rgiht extension of the file" do 
    expect(subject.current.path.end_with?("log")).to be_truthy
  end 

  it "do rotate operation correctly" do 
    subject.rotate!
    expect(subject.counter).to eq(2)
  end 

  it "can access current file io" do 
    expect(subject.current).to be_kind_of(LogStash::Outputs::Qingstor::TemporaryFile)
  end 
end 