require 'net/http/server/parser'
require 'net/http/server/requests'
require 'net/http/server/responses'

require 'net/protocol'
require 'threaded_server'

module Net
  class HTTP < Protocol
    module Server
      class Daemon < ThreadedServer

        include Requests
        include Responses

        # Default host to bind to.
        DEFAULT_HOST = '0.0.0.0'

        # Default port to listen on.
        DEFAULT_PORT = 8080

        #
        # Creates a new HTTP Daemon.
        #
        # @param [Hash] options
        #   Options for the daemon.
        #
        # @option options [String] :host (DEFAULT_HOST)
        #   The host to run on.
        #
        # @option options [String] :port (DEFAULT_PORT)
        #   The port to listen on.
        #
        # @option options [Integer] :max_connections (MAX_CONNECTIONS)
        #   The maximum number of simultaneous connections.
        #
        # @option options [IO] :log (STDERR)
        #   The log to write errors to.
        #
        # @option options [#call] :handler
        #   The HTTP Request Handler object.
        #
        # @yield [request, socket]
        #   If a block is given, it will be used to process HTTP Requests.
        #
        # @yieldparam [Hash{Symbol => String,Array,Hash}] request
        #   The HTTP Request.
        #
        # @yieldparam [TCPSocket] socket
        #   The TCP socket of the client.
        #
        def initialize(options={},&block)
          @app = (options.delete(:app) || block)

          host = (options.delete(:host) || DEFAULT_HOST)
          port = (options.delete(:port) || DEFAULT_PORT)

          super(host,port,options) { |socket| serve(socket) }
        end

        def self.run(options={},&block)
          daemon = new(options,&block)
          daemon.listen

          return daemon
        end

        #
        # Receives HTTP Requests and handles them.
        #
        # @param [TCPSocket] socket
        #   A new TCP connection.
        #
        def serve(socket)
          if (raw_request = read_request(socket))
            parser = Parser.new

            begin
              request = parser.parse(raw_request)
            rescue Parslet::ParseFailed => error
              return Responses::BAD_REQUEST
            end

            normalize_request(request)

            # rack compliant
            status, headers, body = @app.call(request,socket)

            write_response(socket,status,headers,body)
          end
        end

      end
    end
  end
end
