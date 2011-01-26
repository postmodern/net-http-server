require 'net/http/server/daemon'
require 'net/http/server/version'

require 'rack'
require 'set'

module Rack
  module Handler
    #
    # A Rack handler for {Net::HTTP::Server}.
    #
    class HTTP

      # The default environment settings.
      DEFAULT_ENV = {
        'rack.version' => Rack::VERSION,
        'rack.errors' => STDERR,
        'rack.multithread' => true,
        'rack.multiprocess' => false,
        'rack.run_once' => false,
        'rack.url_scheme' => 'http',

        'SERVER_SOFTWARE' => "Net::HTTP::Server/#{Net::HTTP::Server::VERSION} (Ruby/#{RUBY_VERSION}/#{RUBY_RELEASE_DATE})",
        'SCRIPT_NAME' => ''
      }

      # Special HTTP Headers used by Rack::Request
      SPECIAL_HEADERS = Set[
        'Content-Type',
        'Content-Length',
      ]

      #
      # Initializes the handler.
      #
      # @param [#call] app
      #   The application the handler will be passing requests to.
      #
      # @param [Hash] options
      #   Additional options.
      #
      # @option options [String] :Host
      #   The host to bind to.
      #
      # @option options [Integer] :Port
      #   The port to listen on.
      #
      def initialize(app,options={})
        @app = app
        @options = options

        @server = nil
      end

      #
      # Creates a new handler and begins handling HTTP Requests.
      #
      # @see #initialize
      #
      def self.run(app,options={})
        new(app,options).run
      end

      #
      # Starts {Net::HTTP::Server} and begins handling HTTP Requests.
      #
      def run
        @server = Net::HTTP::Server::Daemon.new(
          :host => @options[:Host],
          :port => @options[:Port],
          :handler => self
        )

        @server.start
        @server.join
      end

      #
      # Handles an HTTP Request.
      #
      # @param [Hash] request
      #   An HTTP Request received from {Net::HTTP::Server}.
      #
      # @param [TCPSocket] socket
      #   The socket that the request was received from.
      #
      # @return [Array<Integer, Hash, Array>]
      #   The response status, headers and body.
      #
      def call(request,socket)
        request_uri = request[:uri]
        remote_address = socket.remote_address
        local_address = socket.local_address

        env = {}

        # add the default values
        env.merge!(DEFAULT_ENV)

        # populate
        env['rack.input'] = socket

        if request_uri[:scheme]
          env['rack.url_scheme'] = request_uri[:scheme]
        end

        env['SERVER_NAME'] = local_address.getnameinfo[0]
        env['SERVER_PORT'] = local_address.ip_port.to_s
        env['SERVER_PROTOCOL'] = "HTTP/#{request[:http_version]}"

        env['REMOTE_ADDR'] = remote_address.ip_address
        env['REMOTE_PORT'] = remote_address.ip_port.to_s

        env['REQUEST_METHOD'] = request[:method]
        env['PATH_INFO'] = request_uri.fetch(:path,'*')
        env['QUERY_STRING'] = request_uri[:query_string].to_s

        # add the headers
        request[:headers].each do |name,value|
          key = name.dup
          
          key.upcase!
          key.tr!('-','_')

          # if the header is not special, prepend 'HTTP_'
          unless SPECIAL_HEADERS.include?(name)
            key.insert(0,'HTTP_')
          end

          env[key] = case value
                     when Array
                       value.join("\n")
                     else
                       value.to_s
                     end
        end

        @app.call(env)
      end

      #
      # Determines if the handler is running.
      #
      # @return [Boolean]
      #   Specifies whether the handler is still running.
      #
      def running?
        @server && !(@server.stopped?)
      end

      #
      # Determines whether the handler was stopped.
      #
      # @return [Boolean]
      #   Specifies whether the handler was previously stopped.
      #
      def stopped?
        @server.nil? || @server.stopped?
      end

      #
      # Stops the handler.
      #
      def stop
        @server.stop if @server
      end

    end
  end
end
