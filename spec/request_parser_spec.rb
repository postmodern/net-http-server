require 'spec_helper'
require 'net/http/request_parser'

describe Net::HTTP::RequestParser do
  it "should not parse garbage" do
    garbage = (1..255).map { |b| b.chr }.join * 100

    lambda {
      subject.parse(garbage)
    }.should raise_error(Parslet::ParseFailed)
  end

  describe "request line" do
    it "should parse non-standard request methods" do
      request = subject.parse("FOO / HTTP/1.1\r\n\r\n")

      request[:method].should == 'FOO'
    end

    it "should parse absolute paths" do
      request = subject.parse("GET /absolute/path HTTP/1.1\r\n\r\n")

      request[:uri][:path].should == 'absolute/path'
    end

    it "should parse the params in the path" do
      request = subject.parse("GET /path;q=1;p=2 HTTP/1.1\r\n\r\n")

      request[:uri][:path].should == 'path'
      request[:uri][:params].should == 'q=1;p=2'
    end

    it "should parse the query-params in the path" do
      request = subject.parse("GET /path?q=1&p=2 HTTP/1.1\r\n\r\n")

      request[:uri][:path].should == 'path'
      request[:uri][:query_string].should == 'q=1&p=2'
    end

    it "should parse absolute URIs paths" do
      request = subject.parse("GET http://www.example.com/path HTTP/1.1\r\n\r\n")

      request[:uri][:scheme].should == 'http'
      request[:uri][:host].should == 'www.example.com'
      request[:uri][:path].should == 'path'
    end

    it "should parse non-http URIs" do
      request = subject.parse("GET xmpp://alice:secret@example.com/path HTTP/1.1\r\n\r\n")

      request[:uri][:scheme].should == 'xmpp'
      request[:uri][:user_info].should == 'alice:secret'
      request[:uri][:host].should == 'example.com'
      request[:uri][:path].should == 'path'
    end

    it "should parse the HTTP version" do
      request = subject.parse("GET /path HTTP/1.1\r\n\r\n")

      request[:version].should == '1.1'
    end

    it "should allow future HTTP versions" do
      request = subject.parse("GET /path HTTP/2.0\r\n\r\n")

      request[:version].should == '2.0'
    end

    it "should parse simple GET requests" do
      request = subject.parse("GET / HTTP/1.1\r\n\r\n")

      request[:method].should == 'GET'
      request[:uri][:path].should be_nil
      request[:version].should == '1.1'
    end
  end
end
