require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/qingstor/temporary_file"
require "logstash/outputs/qingstor/temporary_file_factory"
require "logstash/outputs/qingstor/file_repository"
require "tmpdir"

describe LogStash::Outputs::Qingstor::FileRepository do 
  let(:tags) { ["tag1", "tag2", "tag3"]}
  let(:encoding) { "none" }
  let(:tmpdir) { File.join(Dir.tmpdir, "lg2qs") }
  let(:prefix) { "aprefix" }

  subject { described_class.new(tags, encoding, tmpdir) }

  it "can get current file io" do 
    subject.get_file(prefix) do |file| 
       expect(file).to be_kind_of(LogStash::Outputs::Qingstor::TemporaryFile)
    end 
  end 

  it "can get current file factory" do 
    subject.get_factory(prefix) do |factory| 
      expect(factory).to be_kind_of(LogStash::Outputs::Qingstor::TemporaryFileFactory)
    end 
  end 
end 