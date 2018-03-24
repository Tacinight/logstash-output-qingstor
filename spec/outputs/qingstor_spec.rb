# encoding: utf-8

require 'logstash/devutils/rspec/spec_helper'
require 'logstash/outputs/qingstor'
require 'logstash/event'
require 'openssl'
require 'fileutils'
require_relative './qs_access_helper'
require_relative './spec_helper'

describe LogStash::Outputs::Qingstor do
  def tmp_dir_path
    File.join(Dir.tmpdir, 'lg_qs_spec')
  end

  let(:prefix) { 'ss/%{server}' }
  let(:event) { LogStash::Event.new('server' => 'overwatch') }
  let(:event_encoded) { 'May the code be with you!' }
  let(:events_and_encoded) { { event => event_encoded } }
  let(:tmpdir) { tmp_dir_path }
  let(:options) do
    {
      'access_key_id' => ENV['access_key_id'],
      'secret_access_key' => ENV['secret_access_key'],
      'bucket' => ENV['bucket'],
      'region' => ENV['region'],
      'prefix' => prefix
    }
  end

  before(:all) do
    FileUtils.mkdir_p(tmp_dir_path) unless File.exist?(tmp_dir_path)
  end

  after(:each) do
    clean_remote_files
  end

  after(:all) do
    FileUtils.rm_rf(tmp_dir_path)
  end

  it 'done work with minimal options' do
    fetch_event(options, events_and_encoded)
    expect(list_remote_file.size).to eq(1)
  end

  it 'use aes256 to encrpytion in the server side' do
    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    cipher.encrypt
    key = cipher.random_key
    fetch_event(options.merge('server_side_encryption_algorithm' => 'AES256',
                              'customer_key' => key),
                events_and_encoded)
    expect(list_remote_file.size).to eq(1)
  end

  it 'upload existing file if turn on restore function' do
    non_empty_file = File.open(File.join(tmpdir, 'non-empty-file'), 'w')
    non_empty_file.write(event_encoded * 10)
    non_empty_file.close
    empty_file = File.open(File.join(tmpdir, 'empty-file'), 'w')
    empty_file.close
    fetch_event(options.merge('restore' => true, 'tmpdir' => tmpdir),
                events_and_encoded)
    expect(list_remote_file.size).to eq(2)
  end

  it 'redirect to the specified host without specified port' do
    new_options = options.merge('host' => 'qingstor.dev', 'port' => 444)
    expect { fetch_event(new_options, events_and_encoded) }
      .to raise_error(QingStor::SDK::NetworkError)
  end

  it 'redirect to the specified host without specified port' do
    new_options = options.merge('host' => 'qingstor.dev', 'port' => 444)
    expect { fetch_event(new_options, events_and_encoded) }
      .to raise_error(QingStor::SDK::NetworkError)
  end
end
