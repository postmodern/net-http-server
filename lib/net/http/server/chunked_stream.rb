require 'net/http/server/stream'

require 'net/protocol'
require 'stringio'

module Net
  class HTTP < Protocol
    module Server
      #
      # Handles reading and writing to Chunked Transfer-Encoded streams.
      #
      # @since 0.2.0
      #
      class ChunkedStream < Stream

        #
        # Initializes the chuked stream.
        #
        # @param [#read, #write, #flush] socket
        #   The socket to read from and write to.
        #
        def initialize(socket)
          super(socket)

          @buffer = ''
        end

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
        # @raise [ArgumentError]
        #   The buffer did not respond to `#<<`.
        #
        # @since 0.2.0
        #
        def read(length=4096,buffer='')
          unless buffer.respond_to?(:<<)
            raise(ArgumentError,"buffer must respond to #<<")
          end

          until @buffer.length >= length
            length_line  = @socket.readline("\r\n").chomp
            chunk_length = length_line.split(';',2).first.to_i(16)

            # read the chunk
            @buffer << @socket.read(chunk_length)

            # chomp the terminating CRLF
            @socket.read(2)

            # end-of-stream
            break if chunk_length == 0
          end

          # clear the buffer before appending
          buffer.replace('')

          unless @buffer.empty?
            # empty a slice of the buffer
            buffer << @buffer.slice!(0,length)
            return buffer
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

          # do not write empty chunks
          unless length == 0
            # write the chunk length
            @socket.write("%X\r\n" % length)

            # write the data
            @socket.write(data)
            @socket.write("\r\n")
            @socket.flush
          end

          return length
        end

        #
        # Closes the chunked stream.
        #
        # @since 0.2.0
        #
        def close
          # last chunk
          @socket.write("0\r\n\r\n")
          @socket.flush
        end

      end
    end
  end
end
