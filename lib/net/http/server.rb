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
      # @yield [request, io]
      #   If a block is given, it will be used to process HTTP Requests.
      #
      # @yieldparam [Hash{Symbol => String,Array,Hash}] request
      #   The HTTP Request.
      #
      # @yieldparam [IO] io
      #   The IO stream of the client.
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
      # @yield [request, io]
      #   If a block is given, it will be used to process HTTP Requests.
      #
      # @yieldparam [Hash{Symbol => String,Array,Hash}] request
      #   The HTTP Request.
      #
      # @yieldparam [IO] io
      #   The IO stream of the client.
      #
      def self.run(options={},&block)
        new(options,&block).start
      end

      #
      # Sets the HTTP Request Processor.
      #
      # @param [#call, nil] processor
      #   The HTTP Request Processor object.
      #
      # @yield [request, io]
      #   If a block is given, it will be used to process HTTP Requests.
      #
      # @yieldparam [Hash{Symbol => String,Array,Hash}] request
      #   The HTTP Request.
      #
      # @yieldparam [IO] io
      #   The IO stream of the client.
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

      def serve(io)
        buffer = []

        io.each_line do |line|
          buffer << line
          break if buffer[-1] == CRLF
        end

        parser = RequestParser.new
        request = begin
                    parser.parse(buffer.join)
                  rescue Parslet::ParseFailed => error
                  end

        @processor.call(request,io) if request
      end

    end
  end
end
