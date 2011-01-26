require 'spec_helper'
require 'net/http/server/daemon'

describe Net::HTTP::Server::Daemon do

  subject { Net::HTTP::Server::Daemon }

  describe "new" do
    it "should have a default host" do
      daemon = subject.new { |request,socket| }

      daemon.host.should_not be_nil
    end

    it "should have a default port" do
      daemon = subject.new { |request,socket| }

      daemon.port.should_not be_nil
    end

    it "should require a HTTP Request handler" do
      lambda {
        subject.new
      }.should raise_error
    end
  end
end
