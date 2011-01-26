require 'net/http/server/parser'
require 'net/http/server/requests'
require 'net/http/server/responses'

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

        # Carriage Return (CR) followed by a Line Feed (LF).
        CRLF = "\r\n"

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
          host = options.fetch(:host,DEFAULT_HOST)
          port = options.fetch(:port,DEFAULT_PORT).to_i
          max_connections = options.fetch(:max_connections,MAX_CONNECTIONS)
          log = options.fetch(:log,STDERR)

          super(port,host,max_connections,log,false,true)

          handler(options[:handler],&block)
        end

        #
        # Sets the HTTP Request Handler.
        #
        # @param [#call, nil] object
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

        def serve(socket)
          buffer = ''

          request_line = socket.readline

          # the request line must contain 'HTTP/'
          unless request_line.include?('HTTP/')
            # invalid request line
            return
          end

          buffer << request_line

          socket.each_line do |header|
            buffer << header

            # a header line must contain a ':' character followed by
            # linear-white-space (either ' ' or "\t").
            unless (header.include?(': ') || header.include?(":\t"))
              # if this is not a header line, check if it is the end
              # of the request
              if header == CRLF
                # end of the request
                break
              else
                # invalid header line
                return
              end
            end
          end

          process_request(socket,buffer)
        end

        protected

        #
        # Processes a request received from the socket.
        #
        # @param [TCPSocket] socket
        #   The socket that received the request.
        #
        # @param [String] raw_request
        #   The received request.
        #
        # @return [Array<status, headers, body>]
        #   The Rack compatible response.
        #
        def process_request(socket,raw_request)
          parser = Parser.new

          begin
            request = parser.parse(raw_request)
          rescue Parslet::ParseFailed => error
            return Responses::BAD_REQUEST
          end

          normalize_request(request)

          # rack compliant
          status, headers, body = @handler.call(request,socket)

          write_response(socket,status,headers,body)
        end

      end
    end
  end
end
