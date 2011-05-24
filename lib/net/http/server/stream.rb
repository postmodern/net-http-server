require 'net/protocol'

module Net
  class HTTP < Protocol
    module Server
      #
      # Handles reading and writing to raw HTTP streams.
      #
      class Stream

        include Enumerable

        #
        # Creates a new stream.
        #
        # @param [IO] stream
        #   The raw stream that will be read/write to.
        #
        # @since 0.2.0
        #
        def initialize(stream)
          @stream = stream
        end

        #
        # Reads data from the stream.
        #
        # @return [String, nil]
        #   A chunk from the stream.
        #
        # @since 0.2.0
        #
        def read
          @stream.read(4096)
        end

        #
        # Reads each chunk from the stream.
        #
        # @yield [chunk]
        #   The given block will be passed each chunk.
        #
        # @yieldparam [String] chunk
        #   A chunk from the stream.
        #
        # @return [Enumerator]
        #   If no block is given, an Enumerator will be returned.
        #
        # @since 0.2.0
        #
        def each
          return enum_for unless block_given?

          while (chunk = read)
            yield chunk
          end
        end

        #
        # Reads the entire body.
        #
        # @return [String]
        #   The complete body.
        #
        # @since 0.2.0
        #
        def body
          buffer = ''

          each { |chunk| buffer << chunk }
          return buffer
        end

        #
        # Writes data to the stream.
        #
        # @param [String] data
        #   The data to write to the stream.
        #
        # @return [Integer]
        #   The length of the data written.
        #
        # @since 0.2.0
        #
        def write(data)
          @stream.write(data)
          @stream.flush(data)
        end

        #
        # @see #write
        #
        # @since 0.2.0
        #
        def <<(data)
          write(data)
        end

        #
        # Closes the stream.
        #
        # @since 0.2.0
        #
        def close
        end

      end
    end
  end
end
