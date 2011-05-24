require 'net/protocol'

module Net
  class HTTP < Protocol
    module Server
      #
      # Handles reading and writing to Chunked Transfer-Encoded streams.
      #
      class ChunkedStream < Stream

        #
        # Reads a chunk from the stream.
        #
        # @param [Integer] length
        #
        # @param [#<<] buffer
        #   The optional buffer to append the data to.
        #
        # @return [String, nil]
        #   A chunk from the stream.
        #
        # @since 0.2.0
        #
        def read(length=4096,buffer=nil)
          length_line = @stream.readline("\r\n").chomp
          length, extension = length_line.split(';',2)
          length = length.to_i(16)

          # read the chunk
          if length > 0
            chunk = @stream.read(length)

            buffer << chunk if buffer
            return chunk
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

      end
    end
  end
end
