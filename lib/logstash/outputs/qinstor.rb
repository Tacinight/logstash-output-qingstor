# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# An qinstor output that does nothing.
class LogStash::Outputs::Qinstor < LogStash::Outputs::Base
  config_name "qinstor"

  public
  def register
  end # def register

  public
  def receive(event)
    return "Event received"
  end # def event
end # class LogStash::Outputs::Qinstor
