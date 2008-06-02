module Workling
  module Starling
    module Routing
      class Base < Hash
        def method_name
          raise Exception.new("method_name not implemented.")
        end
        def build(clazz)
          raise Exception.new("build not implemented.")
        end
      end
    end
  end
end