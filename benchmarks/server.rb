#!/usr/bin/env ruby

require 'rubygems'

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__),'..','lib'))
require 'net/http/server'

puts ">>> Starting the HTTP Server on port 8080 ..."
puts ">>> Prepare to run: ab -n 1000 http://localhost:8080/"

Net::HTTP::Server.run(:port => 8080) do |request,socket|
  [200, {'Content-Type' => 'text/html'}, ['Hello World']]
end
