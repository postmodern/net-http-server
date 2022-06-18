# net-http-server

* [Homepage](http://github.com/postmodern/net-http-server)
* [Issues](http://github.com/postmodern/net-http-server/issues)
* [Documentation](http://rubydoc.info/gems/net-http-server)

## Description

{Net::HTTP::Server} is a pure Ruby HTTP server.

## Features

* Pure Ruby.
* Supports Streamed Request/Response Bodies.
* Supports Chunked Transfer-Encoding.
* Provides a [Rack](http://rack.rubyforge.org/) Handler.

## Examples

Simple HTTP Server:

    require 'net/http/server'
    require 'pp'

    Net::HTTP::Server.run(:port => 8080) do |request,stream|
      pp request

      [200, {'Content-Type' => 'text/html'}, ['Hello World']]
    end

Use it with Rack:

    require 'rack/handler/http'
    
    Rack::Handler::HTTP.run app

Using it with `rackup`:

    $ rackup -s HTTP

## Requirements

* [parslet](http://rubygems.org/gems/parslet) ~> 1.0
* [gserver](https://rubygems.org/gems/gserver) ~> 0.0

## Install

    $ gem install net-http-server

## Copyright

Copyright (c) 2011 Hal Brodigan

See {file:LICENSE.txt} for details.
