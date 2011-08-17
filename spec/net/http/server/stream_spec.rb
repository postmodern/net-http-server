require 'spec_helper'
require 'net/http/server/stream'

describe Net::HTTP::Server::Stream do
  describe "#read" do
    it "should read data from a socket" do
      data = "foo\0bar"

      socket = mock(:socket)
      socket.should_receive(:read).and_return(data)

      stream = described_class.new(socket)
      stream.read.should == data
    end

    it "should read an amount of data from a socket, directly into a buffer" do
      data   = "foo\0bar"
      length = 3
      buffer = ''

      socket = mock(:socket)
      socket.should_receive(:read).with(length,buffer).and_return(data[0,length])

      stream = described_class.new(socket)
      stream.read(length,buffer)
    end
  end

  describe "#each" do
    it "should stop yielding data on 'nil'" do
      results = []

      socket = mock(:socket)
      socket.should_receive(:read).and_return(nil)

      stream = described_class.new(socket)
      stream.each { |chunk| results << chunk }

      results.should be_empty
    end

    it "should yield each chunk in the stream" do
      chunks = ["foo\n\r", "bar\n\r"]
      results = []

      socket = mock(:socket)
      socket.should_receive(:read).and_return(*(chunks + [nil]))

      stream = described_class.new(socket)
      stream.each { |chunk| results << chunk }

      results.should == chunks
    end
  end

  describe "#body" do
    it "should append each chunk to a buffer" do
      chunks = ["foo\n\r", "bar\n\r"]

      socket = mock(:socket)
      socket.should_receive(:read).and_return(*(chunks + [nil]))

      stream = described_class.new(socket)
      stream.body.should == chunks.join('')
    end
  end

  describe "#write" do
    it "should write to the socket and flush" do
      data = "foo\n\rbar"

      socket = mock(:socket)
      socket.should_receive(:write).with(data).and_return(data.length)
      socket.should_receive(:flush).with(no_args)

      stream = described_class.new(socket)
      stream.write(data).should == data.length
    end
  end
end
