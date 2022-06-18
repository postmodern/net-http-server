require 'spec_helper'
require 'net/http/server/parser'

describe Net::HTTP::Server::Parser do
  it "should not parse garbage" do
    garbage = (1..255).map { |b| b.chr }.join * 100

    expect {
      subject.parse(garbage)
    }.to raise_error(Parslet::ParseFailed)
  end

  describe "request line" do
    it "should parse non-standard request methods" do
      request = subject.parse("FOO / HTTP/1.1\r\n\r\n")

      expect(request[:method]).to eq('FOO')
    end

    it "should allow '*' as the path" do
      request = subject.parse("OPTIONS * HTTP/1.1\r\n\r\n")

      expect(request[:uri]).to eq('*')
    end

    it "should not confuse the '/*' path with '*'" do
      request = subject.parse("OPTIONS /* HTTP/1.1\r\n\r\n")

      expect(request[:uri][:path]).to eq('/*')
    end

    it "should parse absolute paths" do
      request = subject.parse("GET /absolute/path HTTP/1.1\r\n\r\n")

      expect(request[:uri][:path]).to eq('/absolute/path')
    end

    it "should parse the params in the path" do
      request = subject.parse("GET /path;q=1;p=2 HTTP/1.1\r\n\r\n")

      expect(request[:uri][:path]).to eq('/path')
      expect(request[:uri][:params]).to eq('q=1;p=2')
    end

    it "should parse the query-string in the path" do
      request = subject.parse("GET /path?q=1&p=2 HTTP/1.1\r\n\r\n")

      expect(request[:uri][:path]).to eq('/path')
      expect(request[:uri][:query]).to eq('q=1&p=2')
    end

    it "should parse absolute URIs paths" do
      request = subject.parse("GET http://www.example.com:8080/path HTTP/1.1\r\n\r\n")

      expect(request[:uri][:scheme]).to eq('http')
      expect(request[:uri][:host]).to eq('www.example.com')
      expect(request[:uri][:port]).to eq('8080')
      expect(request[:uri][:path]).to eq('/path')
    end

    it "should parse non-http URIs" do
      request = subject.parse("GET xmpp://alice:secret@example.com/path HTTP/1.1\r\n\r\n")

      expect(request[:uri][:scheme]).to eq('xmpp')
      expect(request[:uri][:user_info]).to eq('alice:secret')
      expect(request[:uri][:host]).to eq('example.com')
      expect(request[:uri][:path]).to eq('/path')
    end

    it "should parse the HTTP version" do
      request = subject.parse("GET /path HTTP/1.1\r\n\r\n")

      expect(request[:version]).to eq('1.1')
    end

    it "should allow future HTTP versions" do
      request = subject.parse("GET /path HTTP/2.0\r\n\r\n")

      expect(request[:version]).to eq('2.0')
    end

    it "should parse simple GET requests" do
      request = subject.parse("GET / HTTP/1.1\r\n\r\n")

      expect(request[:method]).to eq('GET')
      expect(request[:uri][:path]).to eq('/')
      expect(request[:version]).to eq('1.1')
    end
  end
end
