require 'net/http/server/daemon'

module Net
  module HTTP
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
        daemon = Daemon.new(options,&block)

        daemon.start
        return daemon
      end

    end
  end
end
