require 'net/http/request_parser'
require 'net/http/request_normalizer'

require 'gserver'
require 'time'

module Net
  module HTTP
    class Server < GServer

      # Default host to run on.
      DEFAULT_HOST = 'localhost'

      # Default port to listen on.
      DEFAULT_PORT = 8080

      # Maximum number of simultaneous connections.
      MAX_CONNECTIONS = 256

      # The supported HTTP Server'
      HTTP_VERSION = '1.1'

      # The known HTTP Status codes and messages
      HTTP_STATUSES = {
        # 1xx
        100 => 'Continue',
        101 => 'Switching Protocols',
        102 => 'Processing',
        # 2xx
        200 => 'OK',
        201 => 'Created',
        202 => 'Accepted',
        203 => 'Non-Authoritative Information',
        204 => 'No Content',
        205 => 'Reset Content',
        206 => 'Partial Content',
        # 3xx
        300 => 'Multiple Choices',
        301 => 'Moved Permanently',
        302 => 'Found',
        303 => 'See Other',
        304 => 'Not Modified',
        305 => 'Use Proxy',
        307 => 'Temporary Redirect',
        # 4xx
        400 => 'Bad Request',
        401 => 'Unauthorized',
        402 => 'Payment Required',
        403 => 'Forbidden',
        404 => 'Not Found',
        405 => 'Method Not Allowed',
        406 => 'Not Acceptable',
        407 => 'Proxy Authentication Required',
        408 => 'Request Time-out',
        409 => 'Conflict',
        410 => 'Gone',
        411 => 'Length Required',
        412 => 'Precondition Failed',
        413 => 'Request Entity Too Large',
        414 => 'Request-URI Too Large',
        415 => 'Unsupported Media Type',
        416 => 'Requested range not satisfiable',
        417 => 'Expectation Failed',
        # 5xx
        500 => 'Internal Server Error',
        501 => 'Not Implemented',
        502 => 'Bad Gateway',
        503 => 'Service Unavailable',
        504 => 'Gateway Time-out',
        505 => 'HTTP Version not supported extension-code'
      }

      # Carriage Return (CR) followed by a Line Feed (LF).
      CRLF = "\r\n"

      # Generic Bad Request response
      BAD_REQUEST = [400, {}, ['Bad Request']]

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

        # rack compliant
        status, headers, body = process_request(socket,buffer)

        send_status(socket,status)
        send_headers(socket,headers)
        send_body(socket,body)
      end

      protected

      include RequestNormalizer

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
        parser = RequestParser.new

        begin
          request = parser.parse(raw_request)
        rescue Parslet::ParseFailed => error
          return BAD_REQUEST
        end

        normalize_request(request)

        @processor.call(request,socket)
      end

      #
      # Writes the status of an HTTP Response to the socket.
      #
      # @param [TCPSocket] socket
      #   The socket to write the headers back to.
      #
      # @param [Integer] status
      #   The status of the HTTP Response.
      #
      def send_status(socket,status)
        status = status.to_i

        reason = HTTP_STATUSES[status]
        socket.write("HTTP/#{HTTP_VERSION} #{status} #{reason}#{CRLF}")
      end

      #
      # Write the headers of an HTTP Response to the socket.
      #
      # @param [TCPSocket] socket
      #   The socket to write the headers back to.
      #
      # @param [Hash{String => String}] headers
      #   The headers of the HTTP Response.
      #
      def send_headers(socket,headers)
        headers.each do |name,values|
          case values
          when String
            values.each_line("\n") do |value|
              socket.write("#{name}: #{value.chomp}#{CRLF}")
            end
          when Time
            socket.write("#{name}: #{values.httpdate}#{CRLF}")
          when Array
            values.each do |value|
              socket.write("#{name}: #{value}#{CRLF}")
            end
          end
        end

        socket.write(CRLF)
        socket.flush
      end

      #
      # Writes the body of a HTTP Response to the socket.
      #
      # @param [TCPSocket] socket
      #   The socket to write the headers back to.
      #
      # @param [#each] body
      #   The body of the HTTP Response.
      #
      def send_body(socket,body)
        body.each do |chunk|
          socket.write(chunk)
          socket.flush
        end
      end

    end
  end
end
