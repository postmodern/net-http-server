require 'net/http/server'

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
        'rack.run_once' => false
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
        @server = Net::HTTP::Server.new(
          :host => @options[:Host],
          :port => @options[:Port].to_i,
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
        env = {
          'rack.input' => socket,
          'rack.url_scheme' => request[:uri].fetch(:scheme,'http'),

          'REQUEST_METHOD' => request[:method],
          'PATH_INFO' => request[:uri][:path],
          'QUERY_STRING' => request[:uri][:query_string]
        }

        # add the default values
        env.merge!(DEFAULT_ENV)

        # add the headers
        request[:headers].each do |name,value|
          key = name.dup
          
          key.upcase!
          key.tr!('-','_')

          # if the header is not special, prepend 'HTTP_'
          unless SPECIAL_HEADERS.include?(name)
            key.insert(0,'HTTP_')
          end

          env[key] = value
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
