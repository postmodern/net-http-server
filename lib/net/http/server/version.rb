require 'net/protocol'

module Net
  class HTTP < Protocol
    module Server
      # net-http-server version.
      VERSION = '0.2.1'
    end
  end
end
