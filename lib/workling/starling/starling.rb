module Workling
  module Starling
    def self.config
      config_path = File.join(RAILS_ROOT, 'config', 'starling.yml')
      @@config ||= YAML.load_file(config_path)[ENV['RAILS_ENV'] || 'development'].symbolize_keys
    end    
  end
end