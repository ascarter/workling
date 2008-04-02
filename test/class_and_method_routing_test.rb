require File.dirname(__FILE__) + '/test_helper.rb'

context "class and method routing" do
  specify "should create a queue called utils:echo for a Util class that subclasses worker and has the method echo" do
    routing = Workling::Starling::Routing::ClassAndMethodRouting.new
    routing['utils:echo'].class.to_s.should.equal "Util"
  end
  
  specify "should create a queue called analytics:invites:sent for an Analytics::Invites class that subclasses worker and has the method sent" do
    routing = Workling::Starling::Routing::ClassAndMethodRouting.new
    routing['analytics:invites:sent'].class.to_s.should.equal "Analytics::Invites"
  end
end