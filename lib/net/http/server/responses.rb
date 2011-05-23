require 'net/protocol'
require 'time'

module Net
  class HTTP < Protocol
    module Server
      module Responses
        # The supported HTTP Protocol.
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

        # Generic Bad Request response
        BAD_REQUEST = [400, {}, ['Bad Request']]

        protected

        #
        # Writes the status of an HTTP Response to a stream.
        #
        # @param [IO] stream
        #   The stream to write the headers back to.
        #
        # @param [Integer] status
        #   The status of the HTTP Response.
        #
        def write_status(stream,status)
          status = status.to_i

          reason = HTTP_STATUSES[status]
          stream.write("HTTP/#{HTTP_VERSION} #{status} #{reason}\r\n")
        end

        #
        # Write the headers of an HTTP Response to a stream.
        #
        # @param [IO] stream
        #   The stream to write the headers back to.
        #
        # @param [Hash{String => [String, Time, Array<String>}] headers
        #   The headers of the HTTP Response.
        #
        def write_headers(stream,headers)
          headers.each do |name,values|
            case values
            when String
              values.each_line("\n") do |value|
                stream.write("#{name}: #{value.chomp}\r\n")
              end
            when Time
              stream.write("#{name}: #{values.httpdate}\r\n")
            when Array
              values.each do |value|
                stream.write("#{name}: #{value}\r\n")
              end
            end
          end

          stream.write("\r\n")
          stream.flush
        end

        #
        # Writes the body of a HTTP Response to a stream.
        #
        # @param [IO] stream
        #   The stream to write the headers back to.
        #
        # @param [#each] body
        #   The body of the HTTP Response.
        #
        def write_body(stream,body)
          body.each do |chunk|
            stream.write(chunk)
            stream.flush
          end
        end

        #
        # Writes a HTTP Response to a stream.
        #
        # @param [IO] stream
        #   The stream to write the HTTP Response to.
        #
        # @param [Integer] status
        #   The status of the HTTP Response.
        #
        # @param [Hash{String => [String, Time, Array<String>}] headers
        #   The headers of the HTTP Response.
        #
        # @param [#each] body
        #   The body of the HTTP Response.
        #
        def write_response(stream,status,headers,body)
          write_status stream, status
          write_headers stream, headers
          write_body stream, body

          # if no `Content-Length` or `Transfer-Encoding` was specified,
          # close the stream after writing the response.
          unless headers.has_key?('Content-Length') ||
                 headers.has_key?('Transfer-Encoding')
            stream.close
          end
        end

      end
    end
  end
end
