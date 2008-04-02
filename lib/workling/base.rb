module Workling
  class Base
    def self.inherited(subclass)
      Workling::Discovery.discovered << subclass
    end
    
    # thanks to blaine cook for this suggestion.
    def self.method_missing(method, *args, &block)
      if method.to_s =~ /^asynch_(.*)/
        Workling::Remote.run(self.to_s.dasherize, $1, *args)
      else
        super
      end
    end
  end
end