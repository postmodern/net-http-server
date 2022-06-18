require 'spec_helper'
require 'net/http/server/daemon'

describe Net::HTTP::Server::Daemon do
  subject { described_class }

  describe "#initialize" do
    subject { described_class.new { |request,response| } }

    it "should have a default host" do
      expect(subject.host).not_to be_nil
    end

    it "should have a default port" do
      expect(subject.port).not_to be_nil
    end

    it "should require a HTTP Request handler" do
      expect {
        described_class.new
      }.to raise_error
    end
  end
end
