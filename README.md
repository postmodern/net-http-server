# net-http-server

* [Homepage](https://github.com/postmodern/net-http-server#readme)
* [Issues](https://github.com/postmodern/net-http-server/issues)
* [Documentation](https://rubydoc.info/gems/net-http-server)

## Description

{Net::HTTP::Server} is a pure Ruby HTTP server.

## Features

* Pure Ruby.
* Supports Streamed Request/Response Bodies.
* Supports Chunked Transfer-Encoding.
* Provides a [Rack](https://github.com/rack/rack#readme) Handler.

## Examples

Simple HTTP Server:

```ruby
require 'net/http/server'
require 'pp'

Net::HTTP::Server.run(:port => 8080) do |request,stream|
  pp request

  [200, {'Content-Type' => 'text/html'}, ['Hello World']]
end
```

Use it with Rack:

```ruby
require 'rack/handler/http'

Rack::Handler::HTTP.run app
```

Using it with `rackup`:

```shell
$ rackup -s HTTP
```

## Requirements

* [parslet](http://kschiess.github.io/parslet/) ~> 1.0
* [gserver](https://rubygems.org/gems/gserver) ~> 0.0

## Install

```shell
$ gem install net-http-server
```

## Copyright

Copyright (c) 2011-2022 Hal Brodigan

See {file:LICENSE.txt} for details.
