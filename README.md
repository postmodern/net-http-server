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

    require 'net/http/server'
    require 'pp'

    Net::HTTP::Server.run(:port => 8080) do |request,socket|
      pp request

      [200, {'Content-Type' => 'text/html'}, ['Hello World']]
    end

## Requirements

* [parslet](http://rubygems.org/gems/parslet) ~> 1.0

## Install

    $ gem install net-http-server

## Copyright

See {file:LICENSE.txt} for details.
