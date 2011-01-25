require 'parslet'

module Net
  module HTTP
    #
    # Inspired by:
    #
    # * [Thin](https://github.com/macournoyer/thin/blob/master/ext/thin_parser/common.rl)
    # * [Unicorn](https://github.com/defunkt/unicorn/blob/master/ext/unicorn_http/unicorn_http_common.rl)
    # * [RFC 2616](http://www.w3.org/Protocols/rfc2616/rfc2616.html)
    #
    class RequestParser < Parslet::Parser
      
      #
      # Character Classes
      #
      rule(:digit) { match('[0-9]') }
      rule(:digits) { digit.repeat(1) }
      rule(:xdigit) { digit | match('[a-fA-F]') }
      rule(:upper) { match('[A-Z]') }
      rule(:lower) { match('[a-z]') }
      rule(:alpha) { upper | lower }
      rule(:alnum) { alpha | digit }
      rule(:cntrl) { match('[\x00-\x1f]') }
      rule(:ascii) { match('[\x00-\x7f]') }

      rule(:sp) { str(' ') }
      rule(:lws) { sp | str("\t") }
      rule(:crlf) { str("\r\n") }

      rule(:ctl) { cntrl | str("\x7f") }
      rule(:text) { lws | (ctl.absnt? >> ascii) }
      rule(:safe) { str('$') | str('-') | str('_') | str('.') }
      rule(:extra) {
        str('!') | str('*') | str("'") | str('(') | str(')') | str(',')
      }
      rule(:reserved) {
        str(';') | str('/') | str('?') | str(':') | str('@') | str('&') |
        str('=') | str('+')
      }
      rule(:sorta_safe) { str('"') | str('<') | str('>') }
      rule(:unsafe) { ctl | sp | str('#') | str('%') | sorta_safe }
      rule(:national) {
        (alpha | digit | reserved | extra | safe | unsafe).absnt? >> any
      }

      rule(:unreserved) { alpha | digit | safe | extra | national }
      rule(:escape) { str("%u").maybe >> xdigit >> xdigit }
      rule(:uchar) { unreserved | escape | sorta_safe }
      rule(:pchar) {
        uchar | str(':') | str('@') | str('&') | str('=') | str('+')
      }
      rule(:separators) {
        str('(') | str(')') | str('<') | str('>') | str('@') | str(',') |
        str(';') | str(':') | str("\\") | str('"') | str('/') | str('[') |
        str(']') | str('?') | str('=') | str('{') | str('}') | sp |
        str("\t")
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
        (alpha | digit | str('+') | str('-') | str('.')).repeat
      }
      rule(:host_name) {
        (alnum | str('-') | str('_') | str('.')).repeat(1)
      }
      rule(:user_info) {
        (
          unreserved | escape | str(';') | str(':') | str('&') | str('=') |
          str('+')
        ).repeat(1)
      }

      rule(:path) { pchar.repeat(1) >> (str('/') >> pchar.repeat).repeat }
      rule(:query_string) { (uchar | reserved).repeat }
      rule(:param) { (pchar | str('/')).repeat }
      rule(:params) { param >> (str(';') >> param).repeat }
      rule(:frag) { (uchar | reserved).repeat }

      rule(:relative_path) {
        path.maybe.as(:path) >>
        (str(';') >> params.as(:params)).maybe >>
        (str('?') >> query_string.as(:query)).maybe >>
        (str('#') >> frag.as(:fragment)).maybe
      }
      rule(:absolute_path) { str('/').repeat(1) >> relative_path }

      rule(:absolute_uri) {
        scheme.as(:scheme) >> str(':') >> str('//').maybe >>
        (user_info.as(:user_info) >> str('@')).maybe >>
        host_name.as(:host) >>
        (str(':') >> digits.as(:port)).maybe >>
        absolute_path
      }

      rule(:request_uri) { str('*') | absolute_uri | absolute_path }

      #
      # HTTP Elements
      #
      rule(:request_method) { upper.repeat(1,20) | token.repeat(1) }

      rule(:version_number) { digits >> str('.') >> digits }
      rule(:http_version) { str('HTTP/') >> version_number.as(:version) }
      rule(:request_line) {
        request_method.as(:method) >>
        sp >> request_uri.as(:uri) >>
        sp >> http_version
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

    end
  end
end
