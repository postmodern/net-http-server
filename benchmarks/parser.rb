#!/usr/bin/env ruby

require 'rubygems'

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__),'..','lib'))
require 'net/http/server/parser'

HTTP_REQUEST = [
  'GET /search?q=test&hl=en&fp=1&cad=b&tch=1&ech=1&psi=DBQ4Te_qCI2Y_QaIuPSTCA12955207804903 HTTP/1.1',
  'Host: www.google.com',
  'Referer: http://www.google.com/',
  'Accept: */*',
  'User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_6; en-US) AppleWebKit/534.10 (KHTML, like Gecko) Chrome/8.0.552.237 Safari/534.10',
  'Accept-Encoding: gzip,deflate,sdch',
  'Avail-Dictionary: GeNLY2f-',
  'Accept-Language: en-US,en;q=0.8',
  'Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3',
  'Cookie: NID=43=bgvZmm1C00aC41wQA0Yl5lVPEJZerwnK9LYDFo4Ph9_qBZFfbwT-auI64LZzdquh8StFriEuQfhrIgf_GlVd9erjOGppXZISHpoFgdiUUfpTqUbKC8gbfNh09eZXmcK7; PREF=ID=c28d27fb5ff1280b:U=fedcd44ca2fdef4f:FF=0:LD=en:CR=2:TM=1295517030:LM=1295517030:S=D36Ccqf-FQ78ZWE7',
  '',
  ''
].join("\r\n")

require 'benchmark'

Benchmark.bm do |bench|
  parser = Net::HTTP::Server::Parser.new

  bench.report('parse: ') do
    parser.parse(HTTP_REQUEST)
  end
end
