module Workling
  module Starling
    class Client
      cattr_accessor :starling_url
      cattr_accessor :connection
      
      def initialize
        self.class.read_config unless self.class.connection
      end
      
      def self.read_config
        config = YAML.load( IO.read(::RAILS_ROOT + "/config/starling.yml") )
        self.starling_url = config[::RAILS_ENV]["listens_on"]
        self.connection = ::MemCache.new self.starling_url
      end
      
      def method_missing(method, *args)
        self.class.connection.send(method, *args)
      end
    end
  end
end