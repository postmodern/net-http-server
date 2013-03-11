require 'net/http/server/parser'
require 'net/http/server/requests'
require 'net/http/server/responses'
require 'net/http/server/stream'
require 'net/http/server/chunked_stream'

require 'net/protocol'
require 'gserver'

module Net
  class HTTP < Protocol
    module Server
      class Daemon < GServer

        include Requests
        include Responses

        # Default host to bind to.
        DEFAULT_HOST = '0.0.0.0'

        # Default port to listen on.
        DEFAULT_PORT = 8080

        # Maximum number of simultaneous connections.
        MAX_CONNECTIONS = 256

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
        # @option options [IO] :log ($stderr)
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
          host = options.fetch(:host,DEFAULT_HOST)
          port = options.fetch(:port,DEFAULT_PORT).to_i
          max_connections = options.fetch(:max_connections,MAX_CONNECTIONS)
          log = options.fetch(:log,$stderr)

          super(port,host,max_connections,log,false,true)

          handler(options[:handler],&block)
        end

        #
        # Sets the HTTP Request Handler.
        #
        # @param [#call, nil] object
        #   The HTTP Request Handler object.
        #
        # @yield [request, stream]
        #   If a block is given, it will be used to process HTTP Requests.
        #
        # @yieldparam [Hash{Symbol => String,Array,Hash}] request
        #   The HTTP Request.
        #
        # @yieldparam [Stream, ChunkedStream] stream
        #   The stream of the HTTP Request body.
        #
        # @raise [ArgumentError]
        #   The HTTP Request Handler must respond to `#call`.
        #
        def handler(object=nil,&block)
          if object
            unless object.respond_to?(:call)
              raise(ArgumentError,"HTTP Request Handler must respond to #call")
            end
          elsif block.nil?
            raise(ArgumentError,"no HTTP Request Handler block given")
          end

          @handler = (object || block)
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
            rescue Parslet::ParseFailed
              return Responses::BAD_REQUEST
            end

            normalize_request(request)

            stream = if request[:headers]['Transfer-Encoding'] == 'chunked'
                       ChunkedStream.new(socket)
                     else
                       Stream.new(socket)
                     end

            # rack compliant
            status, headers, body = @handler.call(request,stream)

            write_response(socket,status,headers,body)
          end
        end

      end
    end
  end
end
