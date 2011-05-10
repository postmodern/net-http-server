require 'net/http/server/daemon'

require 'net/protocol'

module Net
  class HTTP < Protocol
    module Server
      #
      # Starts the HTTP Server.
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
      # @option options [Boolean] :background (false)
      #   Specifies whether to run the server in the background or
      #   foreground.
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
      def Server.run(options={},&block)
        Daemon.run(options,&block)
      end

    end
  end
end
