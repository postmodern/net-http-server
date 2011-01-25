module Net
  module HTTP
    module Server
      module Requests

        # Default ports for common URI schemes
        DEFAULT_PORTS = {
          'https' => 443,
          'http' => 80
        }

        protected

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
