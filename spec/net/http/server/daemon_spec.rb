require 'spec_helper'
require 'net/http/server/daemon'

describe Net::HTTP::Server::Daemon do
  subject { described_class }

  describe "#initialize" do
    subject { described_class.new { |request,response| } }

    it "should have a default host" do
      expect(subject.host).to eq(described_class::DEFAULT_HOST)
    end

    it "should have a default port" do
      expect(subject.port).to eq(described_class::DEFAULT_PORT)
    end

    it "should require a HTTP Request handler" do
      expect {
        described_class.new
      }.to raise_error(ArgumentError,"no HTTP Request Handler block given")
    end
  end
end
