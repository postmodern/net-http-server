require 'spec_helper'
require 'net/http/server/daemon'

describe Net::HTTP::Server::Daemon do
  subject { described_class }

  describe "#initialize" do
    subject { described_class.new { |request,response| } }

    it "should have a default host" do
      subject.host.should_not be_nil
    end

    it "should have a default port" do
      subject.port.should_not be_nil
    end

    it "should require a HTTP Request handler" do
      lambda {
        described_class.new
      }.should raise_error
    end
  end
end
