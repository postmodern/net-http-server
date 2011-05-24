require 'net/protocol'

module Net
  class HTTP < Protocol
    module Server
      #
      # Handles reading and writing to Chunked Transfer-Encoded streams.
      #
      class ChunkedStream

        include Enumerable

        #
        # Creates a new chunked stream.
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

          loop do
            length_line = @stream.readline("\r\n").chomp
            length, extension = length_line.split(';',2)
            length = length.to_i(16)

            # read the chunk
            yield @stream.read(length)

            # read the following CRLF
            @stream.read(2)

            # break when we receive the 0 chunk
            break if length == 0
          end
        end

        #
        # Writes data to the chunked stream.
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
          length = data.length

          # write the chunk length
          @stream.write("%X\r\n" % length)
          @stream.write(data)
          @stream.write("\r\n")
          @stream.flush

          return length
        end

        alias << write

        #
        # Closes the chunked stream.
        #
        # @since 0.2.0
        #
        def close
          # last chunk
          @stream.write("0\r\n\r\n")
          @stream.flush
        end

        alias finish close

      end
    end
  end
end
