# encoding: utf-8

require 'logstash/devutils/rspec/spec_helper'
require 'logstash/outputs/qingstor/qingstor_validator'
require_relative '../qs_access_helper'

describe LogStash::Outputs::Qingstor::QingstorValidator do
  let(:normal_prefix) { 'super/bucket' }
  let(:wrong_prefix1) { '/wrong/prefix' }
  let(:wrong_prefix2) { normal_prefix * 100 }
  let(:bucket) { qs_bucket_init }

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
