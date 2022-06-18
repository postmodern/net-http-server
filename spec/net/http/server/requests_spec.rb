require 'spec_helper'
require 'net/http/server/requests'

require 'stringio'

describe Net::HTTP::Server::Requests do
  include Net::HTTP::Server::Requests

  describe "read_request" do
    it "should ignore requests that do not contain an HTTP version" do
      stream = StringIO.new("GET /\r\n")

      expect(read_request(stream)).to be_nil
    end

    it "should ignore requests with malformed headers" do
      stream = StringIO.new("GET / HTTP/1.1\r\nFoo: Bar\r\nBAZ\r\n\r\n")

      expect(read_request(stream)).to be_nil
    end

    it "should read requests with an HTTP Version and Headers" do
      request = "GET / HTTP/1.1\r\nFoo: Bar\r\n\r\n"
      stream = StringIO.new(request)

      expect(read_request(stream)).to eq(request)
    end

    it "should not read the body of the request" do
      request = "GET / HTTP/1.1\r\nFoo: Bar\r\n\r\n"
      body = "<html>\r\n\t<body>hello</body>\r\n</html>\r\n"
      stream = StringIO.new(request + body)

      read_request(stream)

      expect(stream.read).to eq(body)
    end
  end

  describe "normalize_uri" do
    it "should infer the :port, if :scheme is also set" do
      request = {:uri => {:scheme => 'https'}}
      normalize_uri(request)

      expect(request[:uri][:port]).to eq(443)
    end

    it "should convert :port to an Integer" do
      request = {:uri => {:scheme => 'http', :port => '80'}}
      normalize_uri(request)

      expect(request[:uri][:port]).to eq(80)
    end

    it "should replace a '*' URI with an empty Hash" do
      request = {:uri => '*'}
      normalize_uri(request)

      expect(request[:uri]).to eq({})
    end
  end

  describe "normalize_headers" do
    it "should convert empty headers to an empty Hash" do
      request = {:headers => []}
      normalize_headers(request)

      expect(request[:headers]).to eq({})
    end

    it "should convert header names and values into a Hash" do
      request = {:headers => [
        {:name => 'Content-Type', :value => 'text/html'},
        {:name => 'Content-Length', :value => '5'}
      ]}
      normalize_headers(request)

      expect(request[:headers]).to eq({
        'Content-Type' => 'text/html',
        'Content-Length' => '5'
      })
    end

    it "should group duplicate header names into the same Hash key" do
      request = {:headers => [
        {:name => 'Content-Type', :value => 'text/html'},
        {:name => 'Content-Type', :value => 'UTF8'},
      ]}
      normalize_headers(request)

      expect(request[:headers]).to eq({
        'Content-Type' => ['text/html', 'UTF8']
      })
    end
  end
end
