require 'spec_helper'
require 'stringio'

require 'net/http/server/chunked_stream'

describe Net::HTTP::Server::ChunkedStream do
  describe "#read" do
    let(:data) { "foo\0bar" }

    it "should read the length-line and then the following chunk" do
      socket = StringIO.new("%x\r\n%s\r\n0\r\n\r\n" % [data.length, data])
      stream = described_class.new(socket)

      expect(stream.read).to eq(data)
    end

    it "should ignore any extension data, after the length field" do
      socket = StringIO.new("%x;lol\r\n%s\r\n0\r\n\r\n" % [data.length, data])
      stream = described_class.new(socket)

      expect(stream.read).to eq(data)
    end

    it "should read an amount of data from a socket, directly into a buffer" do
      length = 3
      buffer = String.new(encoding: Encoding::UTF_8)

      socket = StringIO.new("%x\r\n%s\r\n0\r\n\r\n" % [data.length, data])
      stream = described_class.new(socket)

      expect(stream.read(length,buffer)).to eq(data[0,length])
    end

    it "should buffer unread data from the previously read chunk" do
      socket = StringIO.new("%x\r\n%s\r\n0\r\n\r\n" % [data.length, data])
      stream = described_class.new(socket)

      expect(stream.read(4)).to eq(data[0,4])
      expect(stream.read).to eq(data[4..-1])
    end

    it "should return nil after it reads the last chunk" do
      socket = StringIO.new("0\r\n\r\n")
      stream = described_class.new(socket)

      expect(stream.read).to be_nil
    end
  end

  describe "#write" do
    it "should return the length of the data written" do
      socket = StringIO.new
      stream = described_class.new(socket)

      expect(stream.write('foo')).to eq(3)
    end

    it "should write a length-line along with the data" do
      socket = StringIO.new
      stream = described_class.new(socket)

      stream.write('foo')

      expect(socket.string).to eq("3\r\nfoo\r\n")
    end

    it "should not write empty Strings" do
      socket = StringIO.new
      stream = described_class.new(socket)

      stream.write('')

      expect(socket.string).to be_empty
    end
  end

  describe "#close" do
    it "should write the 0 length-line" do
      socket = StringIO.new
      stream = described_class.new(socket)

      stream.close

      expect(socket.string).to eq("0\r\n\r\n")
    end
  end
end
