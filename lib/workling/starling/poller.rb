module Workling
  module Starling
    class Poller
      cattr_accessor :sleep_time
      @@sleep_time = 1
    
      def initialize(routing, connection)
        @routing = routing
        @connection = connection
      end
    
      def listen
        loop do
          dispatch!
          sleep self.class.sleep_time
        end
      end
    
      def dispatch!
        for queue in @routing.keys
          begin
            result = @connection.get(queue)
            @routing[queue].send @routing.method_name(queue), result if result
          rescue Exception => e
            puts msg = "FAILED to process queue #{ queue }. #{ @routing[queue] } could not handle invocation of #{ @routing.method_name(queue) } with #{ result.inspect }: #{ e }."
            RAILS_DEFAULT_LOGGER.error(msg)
          end
        end
      end
    end
  end
end