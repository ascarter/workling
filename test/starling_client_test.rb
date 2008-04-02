require File.dirname(__FILE__) + '/test_helper'

context "The starling client" do
  specify "should load it's config from RAILS_ENV/config/starling.yml" do
    client = Workling::Starling::Client.new
    client.starling_url.should.equal "localhost:22122"
  end
end