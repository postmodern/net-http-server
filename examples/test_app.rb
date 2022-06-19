#!/usr/bin/env ruby

require 'sinatra/base'

class TestApp < Sinatra::Base

  get '/' do
    'hello'
  end

  get '/other' do
    halt 404
  end

end

require 'rack/handler/http'

puts "Listening on http://localhost:8080/ ..."
Rack::Handler::HTTP.run Rack::Lint.new(TestApp), Port: 8080
puts "Shutting down ..."
