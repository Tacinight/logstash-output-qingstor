# encoding: utf-8

require 'logstash/devutils/rspec/spec_helper'
require 'logstash/outputs/qingstor/qingstor_validator'

describe LogStash::Outputs::Qingstor::QingstorValidator do
  def get_bucket(config)
    access_key_id = config.fetch('access_key_id')
    secret_access_key = config.fetch('secret_access_key')
    bucket = config.fetch('bucket')
    region = config.fetch('region')
    config = QingStor::SDK::Config.init(access_key_id, secret_access_key)
    properties = { 'bucket-name' => bucket, 'zone' => region }
    QingStor::SDK::Bucket.new(config, properties)
  end

  let(:normal_prefix) { 'super/bucket' }
  let(:wrong_prefix1) { '/wrong/prefix' }
  let(:wrong_prefix2) { normal_prefix * 100 }
  let(:config) do
    { 'access_key_id' => ENV['access_key_id'],
      'secret_access_key' => ENV['secret_access_key'],
      'bucket' => ENV['bucket'],
      'region' => ENV['region'] }
  end

  context 'validate the prefix' do
    it 'raise error if the prefix is not valid' do
      expect { described_class.prefix_valid?(wrong_prefix1) }
        .to raise_error(LogStash::ConfigurationError)
      expect { described_class.prefix_valid?(wrong_prefix2) }
        .to raise_error(LogStash::ConfigurationError)
    end

    it 'return true if the prefix is valid' do
      expect(described_class.prefix_valid?(normal_prefix)).to be_truthy
    end
  end

  context 'validate the bucket' do
    it 'tests with wrong id' do
      config['access_key_id'] = 'wrongid'
      bucket = get_bucket(config)
      expect { described_class.bucket_valid?(bucket) }
        .to raise_error(LogStash::ConfigurationError)
    end

    it 'tests with wrong key' do
      config['secret_access_key'] = 'wrongaccesskey'
      bucket = get_bucket(config)
      expect { described_class.bucket_valid?(bucket) }
        .to raise_error(LogStash::ConfigurationError)
    end

    it 'tests with wrong bucket name' do
      config['bucket'] = 'wrongbucket'
      bucket = get_bucket(config)
      expect { described_class.bucket_valid?(bucket) }
        .to raise_error(LogStash::ConfigurationError)
    end

    it 'tests with wrong reigon name' do
      config['region'] = 'wrongregion'
      bucket = get_bucket(config)
      expect { described_class.bucket_valid?(bucket) }
        .to raise_error(LogStash::ConfigurationError)
    end
  end
end
