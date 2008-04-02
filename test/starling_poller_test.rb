require File.dirname(__FILE__) + '/test_helper.rb'

context "the starling client" do
  setup do
    routing = Workling::Starling::Routing::ClassAndMethodRouting.new
    # the memoryreturnstore behaves exactly like memcache. 
    @connection = Workling::Return::Store::MemoryReturnStore.new
    @client = Workling::Starling::Poller.new(routing, @connection)
  end
  
  specify "should invoke Util.echo with the arg 'hello' if the string 'hello' is set onto the queue utils:echo" do
    Util.any_instance.stubs(:echo).with("hello")
    @connection.set("utils:echo", "hello")
    @client.dispatch!
  end
end