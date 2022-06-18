require 'spec_helper'
require 'net/http/server/responses'

require 'stringio'

describe Net::HTTP::Server::Responses do
  include Net::HTTP::Server::Responses

  before(:each) { @stream = StringIO.new }

  describe "write_status" do
    let(:status) { 200 }
    let(:reason) { Net::HTTP::Server::Responses::HTTP_STATUSES[status] }

    before(:each) { write_status(@stream,status) }

    it "should write the HTTP Version" do
      parts = @stream.string.split(' ')

      expect(parts[0]).to match(/HTTP\/1.1/)
    end

    it "should write the Status Code" do
      parts = @stream.string.split(' ')

      expect(parts[1]).to eq(status.to_s)
    end

    it "should write the Reason String" do
      parts = @stream.string.split(' ')

      expect(parts[2]).to eq(reason)
    end

    it "should end the line with a '\\r\\n'" do
      expect(@stream.string[-2..-1]).to eq("\r\n")
    end
  end

  describe "write_headers" do
    it "should separate header names and values with a ': '" do
      write_headers(@stream, 'Foo' => 'Bar')

      expect(@stream.string).to include(': ')
    end

    it "should terminate each header with a '\\r\\n'" do
      write_headers(@stream, 'Foo' => 'Bar', 'Baz' => 'Qix')

      expect(@stream.string.split("\r\n")).to match_array([
        'Foo: Bar',
        'Baz: Qix'
      ])
    end

    it "should end the headers with a '\\r\\n'" do
      write_headers(@stream, {})

      expect(@stream.string).to eq("\r\n")
    end

    it "should write String headers" do
      write_headers(@stream, 'Content-Type' => 'text/html')

      expect(@stream.string.split("\r\n")).to eq([
        'Content-Type: text/html'
      ])
    end

    it "should write multiple headers for multi-line String values" do
      write_headers(@stream, 'Content-Type' => "text/html\ncharset=UTF8")

      expect(@stream.string.split("\r\n")).to eq([
        'Content-Type: text/html',
        'Content-Type: charset=UTF8'
      ])
    end

    it "should properly format Time values" do
      time = Time.parse('2011-01-25 14:15:29 -0800')
      write_headers(@stream, 'Date' => time)

      expect(@stream.string.split("\r\n")).to eq([
        'Date: Tue, 25 Jan 2011 22:15:29 GMT'
      ])
    end

    it "should write Array values as multiple headers" do
      write_headers(@stream, 'Content-Type' => ['text/html', 'charset=UTF8'])

      expect(@stream.string.split("\r\n")).to eq([
        'Content-Type: text/html',
        'Content-Type: charset=UTF8'
      ])
    end
  end

  describe "write_body" do
    it "should write each check of the body" do
      write_body(@stream,['one', 'two', 'three'])

      expect(@stream.string).to eq('onetwothree')
    end
  end
end
