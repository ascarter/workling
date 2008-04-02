require 'workling/starling/routing/base'

module Workling
  module Starling
    module Routing
      class ClassAndMethodRouting < Base
        def initialize
          super
          build
        end
        
        def method_name(queue)
          queue.split(":").last
        end
        
        def queue_for(clazz, method)
          self.class.queue_for(clazz, method)
        end
        
        def self.queue_for(clazz, method)
          "#{ clazz.to_s.tableize }/#{ method }".split("/").join(":")
        end
        
        protected
        def build
          Workling::Discovery.discovered.each do |clazz|
            methods = clazz.instance_methods(false)
            methods.each do |method|
              queue =  queue_for(clazz, method)
              self[queue] = clazz.new
            end
          end
        end
      end
    end
  end
end