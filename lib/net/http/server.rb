require 'net/http/request_parser'

require 'gserver'

module Net
  module HTTP
    class Server < GServer

      # Default host to run on.
      DEFAULT_HOST = 'localhost'

      # Default port to listen on.
      DEFAULT_PORT = 8080

      # Maximum number of simultaneous connections.
      MAX_CONNECTIONS = 256

      # Carriage Return (CR) followed by a Line Feed (LF).
      CRLF = "\r\n"

      #
      # Creates a new HTTP Server.
      #
      # @param [Hash] options
      #   Options for the server.
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
      # @option options [#call] :processor
      #   The HTTP Request Processor object.
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
        port = options.fetch(:port,DEFAULT_PORT)
        max_connections = options.fetch(:max_connections,MAX_CONNECTIONS)

        super(port,host,max_connections)

        processor(options[:processor],&block)
      end

      #
      # Starts the server.
      #
      # @param [Hash] options
      #   Options for the server.
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
      # @option options [#call] :processor
      #   The HTTP Request Processor object.
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
      def self.run(options={},&block)
        server = new(options,&block)

        server.start
        server.join
        return server
      end

      #
      # Sets the HTTP Request Processor.
      #
      # @param [#call, nil] processor
      #   The HTTP Request Processor object.
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
      #   The HTTP Request Processor must respond to `#call`.
      #
      def processor(processor=nil,&block)
        if processor
          unless processor.respond_to?(:call)
            raise(ArgumentError,"HTTP Request Processor must respond to #call")
          end
        elsif block.nil?
          raise(ArgumentError,"no HTTP Request Processor block given")
        end

        @processor = (processor || block)
      end

      def serve(socket)
        buffer = []

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

        parser = RequestParser.new
        request = begin
                    parser.parse(buffer.join)
                  rescue Parslet::ParseFailed => error
                  end

        @processor.call(request,socket) if request
      end

    end
  end
end
