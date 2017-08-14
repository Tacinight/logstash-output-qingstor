# encoding: utf-8

require 'logstash/devutils/rspec/spec_helper'
require 'logstash/outputs/qingstor/temporary_file'
require 'fileutils'
require 'tmpdir'

describe LogStash::Outputs::Qingstor::TemporaryFile do
  subject { described_class.new(key, io, tmp_path) }

  let(:key) { 'foo.log' }
  let(:content) { 'May the code be with you!' }
  let(:tmp_path) { File.join(Dir.tmpdir, key) }
  let(:file_mode) { 'w+' }
  let(:io) { ::File.open(tmp_path, file_mode) }

  after(:all) do
    FileUtils.rm_r('/tmp/foo.log') if File.exist?('/tmp/foo.log')
  end

  it 'return the key of the file' do
    expect(subject.key).to eq(key)
  end

  it 'is writable and readable' do
    subject.write(content)
    subject.close
    expect(File.read(subject.path).strip).to eq(content)
  end

  it 'can return the correct file size' do
    subject.write(content)
    subject.close
    expect(subject.size).to eq(File.size(tmp_path))
  end

  it 'return the tmp_path of the file' do
    expect(subject.tmp_path).to eq(tmp_path)
  end

  it 'return the creation time' do
    expect(subject.ctime).to be < Time.now + 1.0
  end

  it 'can delete file correctly' do
    expect(File.exist?(subject.tmp_path)).to be_truthy
    subject.delete!
    expect(File.exist?(subject.tmp_path)).to be_falsey
  end

  it 'return if the file is empty' do
    expect(subject.empty?).to be_truthy
    subject.write(content)
    expect(subject.empty?).to be_falsey
  end
end
