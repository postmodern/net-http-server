require 'spec_helper'
require 'net/http/server/stream'

require 'stringio'

describe Net::HTTP::Server::Stream do
  describe "#read" do
    let(:data) { "foo\0bar" }

    it "should read data from a socket" do
      stream = described_class.new(StringIO.new(data))
      expect(stream.read).to eq(data)
    end

    it "should read an amount of data from a socket, directly into a buffer" do
      length = 3
      buffer = String.new(encoding: Encoding::UTF_8)

      stream = described_class.new(StringIO.new(data))
      stream.read(length,buffer)
      
      expect(buffer).to eq(data[0,length])
    end
  end

  describe "#each" do
    it "should stop yielding data on 'nil'" do
      results = []

      stream = described_class.new(StringIO.new())
      stream.each { |chunk| results << chunk }

      expect(results).to be_empty
    end

    it "should yield each chunk in the stream" do
      chunks = ['A' * 4096, 'B' * 4096]
      data = chunks.join('')
      results = []

      stream = described_class.new(StringIO.new(data))
      stream.each { |chunk| results << chunk }

      expect(results).to eq(chunks)
    end
  end

  describe "#body" do
    it "should append each chunk to a buffer" do
      chunks = ['A' * 4096, 'B' * 4096]
      data = chunks.join('')

      stream = described_class.new(StringIO.new(data))
      expect(stream.body).to eq(data)
    end
  end

  describe "#write" do
    it "should write to the socket and flush" do
      data = "foo\n\rbar"

      stream = described_class.new(StringIO.new)
      expect(stream.write(data)).to eq(data.length)
    end
  end
end
