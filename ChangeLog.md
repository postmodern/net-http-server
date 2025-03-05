### 0.2.4 / 2025-03-04

* Support Ruby 3.4.0:
  * No longer use mutable String literals, and instead use
    `String.new(encoding: Encoding::UTF_8)` to fix warnings under Ruby 3.4.0.

### 0.2.3 / 2022-06-18

* Add [gserver] ~> 0.0 as a dependency.
* Switched to using Ruby 2.x keyword arguments.
* Fix a bug in {Rack::Handler::HTTP} where the URI `query` string was not being
  properly loaded.
* Fixed a bug in {Net::HTTP::Server::Parser} where the older `absnt?` method
  was being used instead of the newer `absent?` method.

### 0.2.2 / 2012-09-08

* Added an example `rackup` command.

#### Parser

* Fixed the rule for escaped unicode characters (`%uXXXX`).
* Added a rule for escaped characters (`%XX`).

### 0.2.1 / 2011-10-14

* Adjusted {Net::HTTP::Server::Parser} to include the leading `/` in the
  `:path`.
* Use `String#replace` to clear the buffer passed to
  {Net::HTTP::Server::ChunkedStream#read}.

### 0.2.0 / 2011-08-23

* Added support for handling Streams and Chunked Transfer-Encoding:
  * Added {Net::HTTP::Server::Stream}.
  * Added {Net::HTTP::Server::ChunkedStream}.
  * Added {Net::HTTP::Server::Responses#write_body_streamed}.
* Use `Rack::RewindableInput` with {Net::HTTP::Server::Stream}.
* Fixed a bug where Parslet Strings were being returned in the Headers.
* Catch all IOErrors in {Net::HTTP::Server::Requests#read_request}.

### 0.1.0 / 2011-01-26

* Initial release:
  * Added {Net::HTTP::Server::Parser}.
  * Added {Net::HTTP::Server::Requests}.
  * Added {Net::HTTP::Server::Responses}.
  * Added {Net::HTTP::Server::Daemon}.
  * Added {Rack::Handler::HTTP}.

[gserver]: https://rubygems.org/gems/gserver
