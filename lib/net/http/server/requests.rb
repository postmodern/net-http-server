require 'net/protocol'

module Net
  class HTTP < Protocol
    module Server
      module Requests
        # Default ports for common URI schemes
        DEFAULT_PORTS = {
          'https' => 443,
          'http' => 80
        }

        protected

        #
        # Reads a HTTP Request from the stream.
        #
        # @param [IO] stream
        #   The stream to read from.
        #
        # @return [String, nil]
        #   The raw HTTP Request or `nil` if the Request was malformed.
        #
        def read_request(stream)
          buffer = ''

          begin
            request_line = stream.readline("\r\n")

            # the request line must contain 'HTTP/'
            return unless request_line.include?('HTTP/')

            buffer << request_line

            stream.each_line("\r\n") do |header|
              buffer << header

              # a header line must contain a ':' character followed by
              # linear-white-space (either ' ' or "\t").
              unless (header.include?(': ') || header.include?(":\t"))
                # if this is not a header line, check if it is the end
                # of the request
                if header == "\r\n"
                  # end of the request
                  break
                else
                  # invalid header line
                  return
                end
              end
            end
          rescue IOError, SystemCallError
            return
          end

          return buffer
        end

        #
        # Normalizes the `:uri` part of the request.
        #
        # @param [Hash] request
        #   The unnormalized HTTP request.
        #
        def normalize_uri(request)
          uri = request[:uri]

          if uri.kind_of?(Hash)
            if uri[:scheme]
              uri[:port] = unless uri[:port]
                             DEFAULT_PORTS[uri[:scheme]]
                           else
                             uri[:port].to_i
                           end
            end

            unless uri[:path]
              uri[:path] = '/'
            else
              uri[:path].insert(0,'/')
            end
          elsif uri == '*'
            request[:uri] = {}
          end
        end

        #
        # Normalizes the `:headers` part of the request.
        #
        # @param [Hash] request
        #   The unnormalized HTTP request.
        #
        def normalize_headers(request)
          headers = request[:headers]
          normalized_headers = {}

          unless headers.empty?
            headers.each do |header|
              name = header[:name]
              value = header[:value]

              if normalized_headers.has_key?(name)
                previous_value = normalized_headers[name]

                if previous_value.kind_of?(Array)
                  previous_value << value
                else
                  normalized_headers[name] = [previous_value, value]
                end
              else
                normalized_headers[name] = value
              end
            end
          end

          request[:headers] = normalized_headers
        end

        #
        # Normalizes a HTTP request.
        #
        # @param [Hash] request
        #   The unnormalized HTTP request.
        #
        def normalize_request(request)
          normalize_uri(request)
          normalize_headers(request)
        end

      end
    end
  end
end
