require 'rack'

module Rack
  module Handler
    class HTTP

      DEFAULT_ENV = {
        'rack.version' => Rack::VERSION,
        'rack.errors' => STDERR,
        'rack.multithread' => true,
        'rack.multiprocess' => false,
        'rack.run_once' => false
      }

      def initialize(app,options={})
        @app = app
        @options = options

        @server = nil
      end

      def self.run(app,options={})
        new(app,options).run
      end

      def run
        @server = Net::HTTP::Server.new(
          :host => options[:Host],
          :port => options[:Port].to_i,
          :processor = self
        )

        @server.start
        @server.join
      end

      def call(request,stream)
      end

      def running?
        @server && !(@server.stopped?)
      end

      def stopped?
        @server.nil? || @server.stopped?
      end

      def stop
        @server.stop if @server
      end

    end
  end
end
