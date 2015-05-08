require 'net/http'
require 'yaml'

# Borrowed from Rack's own specs.
class TestRequest
  def call(env)
    status = env["QUERY_STRING"] =~ /secret/ ? 403 : 200
    env["test.postdata"] = env["rack.input"].read
    # clean out complex objects that won't translate over anyways.
    env.keys.each do |key|
      case env[key]
      when String, Fixnum, Bignum
        # leave it
      else
        env[key] = nil
      end
    end
    body = env.to_yaml
    size = body.respond_to?(:bytesize) ? body.bytesize : body.size
    [status, {"Content-Type" => "text/yaml", "Content-Length" => size.to_s}, [body]]
  end

  module Helpers
    attr_reader :status, :response

    ROOT = File.expand_path(File.dirname(__FILE__) + "/..")
    ENV["RUBYOPT"] = "-I#{ROOT}/lib -rubygems"

    def root
      ROOT
    end

    def rackup
      "#{ROOT}/bin/rackup"
    end

    def GET(path, header={})
      Net::HTTP.start(@host, @port) { |http|
        user = header.delete(:user)
        passwd = header.delete(:passwd)

        get = Net::HTTP::Get.new(path, header)
        get.basic_auth user, passwd  if user && passwd
        http.request(get) { |response|
          @status = response.code.to_i
          if response.content_type == "text/yaml"
            load_yaml(response)
          else
            @response = response
          end
        }
      }
    end

    def POST(path, formdata={}, header={})
      Net::HTTP.start(@host, @port) { |http|
        user = header.delete(:user)
        passwd = header.delete(:passwd)

        post = Net::HTTP::Post.new(path, header)
        post.form_data = formdata
        post.basic_auth user, passwd  if user && passwd
        http.request(post) { |response|
          @status = response.code.to_i
          @response = YAML.load(response.body)
        }
      }
    end

    def load_yaml(response)
      begin
        @response = YAML.load(response.body)
      rescue ArgumentError
        @response = nil
      end
    end
  end
end
