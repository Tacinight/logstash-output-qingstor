# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/qingstor"
require "logstash/event"
require_relative "./qs_access_helper"

describe LogStash::Outputs::Qingstor do

  let(:prefix) { "super/%{server}"}
  let(:options) {{
    "access_key_id" => ENV['access_key_id'],
    "secret_access_key" => ENV['secret_access_key'],
    "bucket" => ENV['bucket'],
    "region" => ENV['region'],
    "prefix" => prefix
  }}
  let(:event) { LogStash::Event.new({ "server" => "overwatch" }) }
  let(:event_encoded) { "May the code be with you!" }
  let(:events_and_encoded) {{ event => event_encoded}}

  subject { described_class.new(options) }

  context "reveicing events" do 
    before do
      subject.register
    end

    after do 
      subject.close 
    end 

    it "uses 'Event#sprintf' for the prefix" do 
      expect(event).to receive(:sprintf).with(prefix).and_return("super/overwatch")
      subject.multi_receive_encoded(events_and_encoded)
    end
  end 

end