require 'net/http/server/daemon'

require 'net/protocol'

module Net
  class HTTP < Protocol
    module Server
      #
      # Starts the HTTP Server.
      #
      # @param [Boolean] background
      #   Specifies whether to run the server in the background or
      #   foreground.
      #
      # @param [Hash{Symbol => Object}] kwargs
      #   Additional keyword arguments for {Daemon#initialize}.
      #
      # @option kwargs [String] :host (DEFAULT_HOST)
      #   The host to run on.
      #
      # @option kwargs [String] :port (DEFAULT_PORT)
      #   The port to listen on.
      #
      # @option kwargs [Integer] :max_connections (MAX_CONNECTIONS)
      #   The maximum number of simultaneous connections.
      #
      # @option kwargs [#call] :handler
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
      #   No `handler:` value was given.
      #
      def Server.run(background: false, **kwargs,&block)
        daemon = Daemon.new(**kwargs,&block)

        daemon.start
        daemon.join unless background
        return daemon
      end

    end
  end
end
