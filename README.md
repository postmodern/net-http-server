# net-http-server

* [Homepage](http://github.com/postmodern/net-http-server)
* [Issues](http://github.com/postmodern/net-http-server/issues)
* Postmodern (postmodern.mod3 at gmail.com)

## Description

{Net::HTTP::Server} is a pure Ruby HTTP server.

## Features

* Pure Ruby.
* Provides a [Rack](http://rack.rubyforge.org/) Handler.

## Examples

Simple HTTP Server:

    require 'net/http/server'
    require 'pp'

    Net::HTTP::Server.run(:port => 8080) do |request,socket|
      pp request

      [200, {'Content-Type' => 'text/html'}, ['Hello World']]
    end

Use it with Rack:

    require 'rack/handler/http'
    
    Rack::Handler::HTTP.run app

## Requirements

* [parslet](http://rubygems.org/gems/parslet) ~> 1.0

## Install

    $ gem install net-http-server

## Copyright

See {file:LICENSE.txt} for details.
