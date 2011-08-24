require 'net/protocol'

module Net
  class HTTP < Protocol
    module Server
      #
      # Handles reading and writing to raw HTTP streams.
      #
      # @since 0.2.0
      #
      class Stream

        include Enumerable

        # The raw socket of the stream.
        attr_reader :socket

        #
        # Creates a new stream.
        #
        # @param [TCPSocket] socket
        #   The raw socket that will be read/write to.
        #
        # @since 0.2.0
        #
        def initialize(socket)
          @socket = socket
        end

        #
        # Reads data from the stream.
        #
        # @param [Integer] length
        #   The number of bytes to read.
        #
        # @param [#<<] buffer
        #   The optional buffer to append the data to.
        #
        # @return [String, nil]
        #   A chunk from the stream.
        #
        # @since 0.2.0
        #
        def read(length=4096,buffer='')
          @socket.read(length,buffer)
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
          result = @socket.write(data)

          @socket.flush
          return result
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
