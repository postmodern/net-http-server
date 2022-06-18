require 'net/protocol'
require 'parslet'

module Net
  class HTTP < Protocol
    module Server
      #
      # Inspired by:
      #
      # * [Thin](https://github.com/macournoyer/thin/blob/master/ext/thin_parser/common.rl)
      # * [Unicorn](https://github.com/defunkt/unicorn/blob/master/ext/unicorn_http/unicorn_http_common.rl)
      # * [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html)
      #
      class Parser < Parslet::Parser

        #
        # Character Classes
        #
        rule(:digit) { match['0-9'] }
        rule(:digits) { digit.repeat(1) }
        rule(:xdigit) { digit | match['a-fA-F'] }
        rule(:upper) { match['A-Z'] }
        rule(:lower) { match['a-z'] }
        rule(:alpha) { upper | lower }
        rule(:alnum) { alpha | digit }
        rule(:cntrl) { match['\x00-\x1f'] }
        rule(:ascii) { match['\x00-\x7f'] }

        rule(:lws) { match[" \t"] }
        rule(:crlf) { str("\r\n") }

        rule(:ctl) { cntrl | str("\x7f") }
        rule(:text) { lws | (ctl.absnt? >> ascii) }

        rule(:safe) { charset('$', '-', '_', '.') }
        rule(:extra) { charset('!', '*', "'", '(', ')', ',') }
        rule(:reserved) { charset(';', '/', '?', ':', '@', '&', '=', '+') }
        rule(:sorta_safe) { charset('"', '<', '>') }

        rule(:unsafe) { ctl | charset(' ', '#', '%') | sorta_safe }
        rule(:national) {
          (alpha | digit | reserved | extra | safe | unsafe).absnt? >> any
        }

        rule(:unreserved) { alpha | digit | safe | extra | national }
        rule(:uescape) { str("%u") >> xdigit >> xdigit >> xdigit >> xdigit }
        rule(:escape) { str("%") >> xdigit >> xdigit }
        rule(:uchar) { unreserved | uescape | escape | sorta_safe }
        rule(:pchar) { uchar | charset(':', '@', '&', '=', '+') }
        rule(:separators) {
          lws | charset(
            '(', ')', '<', '>', '@', ',', ';', ':', "\\", '"', '/', '[', ']',
            '?', '=', '{', '}'
          )
        }

        #
        # Elements
        #
        rule(:token) { (ctl | separators).absnt? >> ascii }

        rule(:comment_text) { (str('(') | str(')')).absnt? >> text }
        rule(:comment) { str('(') >> comment_text.repeat >> str(')') }

        rule(:quoted_pair) { str("\\") >> ascii }
        rule(:quoted_text) { quoted_pair | str('"').absnt? >> text }
        rule(:quoted_string) { str('"') >> quoted_text >> str('"') }

        #
        # URI Elements
        #
        rule(:scheme) {
          (alpha | digit | charset('+', '-', '.')).repeat
        }
        rule(:host_name) {
          (alnum | charset('-', '_', '.')).repeat(1)
        }
        rule(:user_info) {
          (
            unreserved | escape | charset(';', ':', '&', '=', '+')
          ).repeat(1)
        }

        rule(:path) { pchar.repeat(1) >> (str('/') >> pchar.repeat).repeat }
        rule(:query_string) { (uchar | reserved).repeat }
        rule(:param) { (pchar | str('/')).repeat }
        rule(:params) { param >> (str(';') >> param).repeat }
        rule(:frag) { (uchar | reserved).repeat }

        rule(:uri_path) {
          (str('/').maybe >> path.maybe).as(:path) >>
          (str(';') >> params.as(:params)).maybe >>
          (str('?') >> query_string.as(:query)).maybe >>
          (str('#') >> frag.as(:fragment)).maybe
        }

        rule(:uri) {
          scheme.as(:scheme) >> str(':') >> str('//').maybe >>
          (user_info.as(:user_info) >> str('@')).maybe >>
          host_name.as(:host) >>
          (str(':') >> digits.as(:port)).maybe >>
          uri_path
        }

        rule(:request_uri) { str('*') | uri | uri_path }

        #
        # HTTP Elements
        #
        rule(:request_method) { upper.repeat(1,20) | token.repeat(1) }

        rule(:version_number) { digits >> str('.') >> digits }
        rule(:http_version) { str('HTTP/') >> version_number.as(:version) }
        rule(:request_line) {
          request_method.as(:method) >> str(' ') >>
          request_uri.as(:uri) >> str(' ') >>
          http_version
        }

        rule(:header_name) { (str(':').absnt? >> token).repeat(1) }
        rule(:header_value) {
          (text | token | separators | quoted_string).repeat(1)
        }

        rule(:header) {
          header_name.as(:name) >> str(':') >> lws.repeat(1) >>
          header_value.as(:value) >> crlf
        }
        rule(:request) {
          request_line >> crlf >>
          header.repeat.as(:headers) >> crlf
        }

        root :request

        protected

        #
        # Creates a matcher for the given characters.
        #
        # @param [Array<String>] chars
        #   The characters to match.
        #
        def charset(*chars)
          match[chars.map { |c| Regexp.escape(c) }.join]
        end

      end
    end
  end
end
