require File.join(File.dirname(__FILE__), 'starling.rb')

module Workling
  module Starling
    class Poller
      cattr_accessor :sleep_time
      cattr_accessor :reset_time
      
      # Default times
      @@sleep_time = 2
      @@reset_time = 30
      
      def initialize(routing)	
        @@sleep_time = Workling::Starling.config[:sleep_time] if Starling.config.has_key?(:sleep_time)
        @@reset_time = Workling::Starling.config[:reset_time] if Starling.config.has_key?(:reset_time)        
        @routing = routing
        @workers = ThreadGroup.new
      end
    
      def listen
        ActiveRecord::Base.allow_concurrency = true
        Workling::Discovery.discovered.each do |clazz|
          RAILS_DEFAULT_LOGGER.debug("Discovered listener #{clazz}")
          clazz_routing = @routing.build(clazz)
          @workers.add(Thread.new(clazz, clazz_routing) { |c, r| clazz_listen(c, r) })
        end
        
        # Wait for all workers to complete
        @workers.list.each { |t| t.join }

        # Clean up all the connections
        ActiveRecord::Base.verify_active_connections!
      end
      
      def stop
        @workers.list.each { |w| w[:shutdown] = true }
      end
      
      ##
      ## Thread procs
      ##
      
      # Listen for one worker class
      def clazz_listen(clazz, clazz_routing)
        RAILS_DEFAULT_LOGGER.debug("Listener thread #{clazz.name} started")
        
        # Read thread configuration if available
        if Starling.config.has_key?(:listeners)
          if Starling.config[:listeners].has_key?(clazz.to_s)
            config = Starling.config[:listeners][clazz.to_s].symbolize_keys
            thread_sleep_time = config[:sleep_time] if config.has_key?(:sleep_time)
          end
        end

        thread_sleep_time ||= self.class.sleep_time
        
        # Setup connection to starling (one per thread)
        connection = Workling::Starling::Client.new
        puts "** Starting Workling::Starling::Client for #{clazz.name} queue"
        
        while (!Thread.current[:shutdown]) do
          begin
            # Keep MySQL connection alive
            unless ActiveRecord::Base.connection.active?
              unless ActiveRecord::Base.connection.reconnect!
                RAILS_DEFAULT_LOGGER.fatal("FAILED - Database not available")
                break
              end
            end

            n = dispatch!(connection, clazz, clazz_routing)
            if n > 0
              RAILS_DEFAULT_LOGGER.debug("Listener thread #{clazz.name} processed #{n.to_s} queue items")
              Thread.pass
            else
              sleep(thread_sleep_time)
            end            
          rescue MemCache::MemCacheError
	          # On memcache error, wait, reset, and try again
            RAILS_DEFAULT_LOGGER.warn("Listener thread #{clazz.name} failed to connect to memcache. Resetting connection.")
            sleep(self.class.reset_time)
            connection = Workling::Starling::Client.new
          end
        end
              
        RAILS_DEFAULT_LOGGER.debug("Listener thread #{clazz.name} ended")
      end
      
      # Dispatcher for one worker class. Will throw MemCacheError if unable to connect.
      # Returns the number of worker methods called
      def dispatch!(connection, clazz, clazz_routing)
        n = 0
        for queue in clazz_routing.keys
          begin
            result = connection.get(queue)
            if result
              n += 1
              handler = clazz_routing[queue]
              method_name = clazz_routing.method_name(queue)
              RAILS_DEFAULT_LOGGER.info("Calling #{handler.class.to_s}\##{method_name}(#{result.inspect})")
              handler.send(method_name, result)
            end
          rescue MemCache::MemCacheError => e
            RAILS_DEFAULT_LOGGER.error("FAILED to connect with queue #{ queue }: #{ e } }")
            raise e
          rescue Object => e
            RAILS_DEFAULT_LOGGER.error("FAILED to process queue #{ queue }. #{ clazz_routing[queue] } could not handle invocation of #{ clazz_routing.method_name(queue) } with #{ result.inspect }: #{ e }.\n#{ e.backtrace.join("\n") }")
          end
        end
        return n
      end
      
    end
  end
end
