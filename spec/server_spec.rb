require 'spec_helper'
require 'net/http/server'

describe Net::Http::Server do
  it "should have a VERSION constant" do
    Net::Http::Server.const_get('VERSION').should_not be_empty
  end
end
