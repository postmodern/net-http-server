require 'spec_helper'
require 'net/http/server/requests'

describe Net::HTTP::Server::Requests do
  include Net::HTTP::Server::Requests

  describe "normalize_uri" do
    it "should infer the :port, if :scheme is also set" do
      request = {:uri => {:scheme => 'https'}}
      normalize_uri(request)

      request[:uri][:port].should == 443
    end

    it "should convert :port to an Integer" do
      request = {:uri => {:scheme => 'http', :port => '80'}}
      normalize_uri(request)

      request[:uri][:port].should == 80
    end

    it "should default :path to '/'" do
      request = {:uri => {:path => nil}}
      normalize_uri(request)

      request[:uri][:path].should == '/'
    end

    it "should ensure that the path begins with a '/'" do
      request = {:uri => {:path => 'foo'}}
      normalize_uri(request)

      request[:uri][:path].should == '/foo'
    end

    it "should replace a '*' URI with an empty Hash" do
      request = {:uri => '*'}
      normalize_uri(request)

      request[:uri].should == {}
    end
  end

  describe "normalize_headers" do
    it "should convert empty headers to an empty Hash" do
      request = {:headers => []}
      normalize_headers(request)

      request[:headers].should == {}
    end

    it "should convert header names and values into a Hash" do
      request = {:headers => [
        {:name => 'Content-Type', :value => 'text/html'},
        {:name => 'Content-Length', :value => '5'}
      ]}
      normalize_headers(request)

      request[:headers].should == {
        'Content-Type' => 'text/html',
        'Content-Length' => '5'
      }
    end

    it "should group duplicate header names into the same Hash key" do
      request = {:headers => [
        {:name => 'Content-Type', :value => 'text/html'},
        {:name => 'Content-Type', :value => 'UTF8'},
      ]}
      normalize_headers(request)

      request[:headers].should == {
        'Content-Type' => ['text/html', 'UTF8']
      }
    end
  end
end
