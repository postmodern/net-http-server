require 'spec_helper'
require 'rack/handler/helpers/test_request'

require 'rack/handler/http'
require 'rack/lint'
require 'rack/builder'
require 'rack/static'

describe Rack::Handler::HTTP do
  include TestRequest::Helpers

  before(:all) do
    app = Rack::Builder.app do
      use Rack::Lint
      use Rack::Static, :urls => ["/images"],
                        :root => TestRequest::Helpers::ROOT
      run TestRequest.new
    end
    
    @host = '127.0.0.1'
    @port = 9204
    @server = Rack::Handler::HTTP.new(app, :Host => @host, :Port => @port)

    Thread.new { @server.run }
    Thread.pass until @server.running?
  end
  
  after(:all) do
    @server.stop
    Thread.pass until @server.stopped?
  end
  
  it "should respond to a simple get request" do
    GET "/"
    expect(status).to eq(200)
  end
  
  it "should have CGI headers on GET" do
    GET("/")
    expect(response["REQUEST_METHOD"]).to eq("GET")
    expect(response["SCRIPT_NAME"]).to eq('')
    expect(response["PATH_INFO"]).to eq("/")
    expect(response["QUERY_STRING"]).to eq("")
    expect(response["test.postdata"]).to eq("")

    GET("/test/foo?quux=1")
    expect(response["REQUEST_METHOD"]).to eq("GET")
    expect(response["SCRIPT_NAME"]).to eq('')
    expect(response["REQUEST_URI"]).to eq("/test/foo")
    expect(response["PATH_INFO"]).to eq("/test/foo")
    expect(response["QUERY_STRING"]).to eq("quux=1")
  end

  it "should have CGI headers on POST" do
    POST("/", {"rack-form-data" => "23"}, {'X-test-header' => '42'})
    expect(status).to eq(200)
    expect(response["REQUEST_METHOD"]).to eq("POST")
    expect(response["REQUEST_URI"]).to eq("/")
    expect(response["QUERY_STRING"]).to eq("")
    expect(response["HTTP_X_TEST_HEADER"]).to eq("42")
    expect(response["test.postdata"]).to eq("rack-form-data=23")
  end

  it "should support HTTP auth" do
    GET("/test", {:user => "ruth", :passwd => "secret"})
    expect(response["HTTP_AUTHORIZATION"]).to eq("Basic cnV0aDpzZWNyZXQ=")
  end

  it "should set status" do
    GET("/test?secret")
    expect(status).to eq(403)
    expect(response["rack.url_scheme"]).to eq("http")
  end

  it "should not set content-type to '' in requests" do
    GET("/test", 'Content-Type' => '')
    expect(response['Content-Type']).to eq(nil)
  end
  
  it "should serve images" do
    file_size = File.size(File.join(File.dirname(__FILE__), 'images', 'image.jpg'))
    GET("/images/image.jpg")
    expect(status).to eq(200)
    expect(response.content_length).to eq(file_size)
    expect(response.body.size).to eq(file_size)
  end
end
