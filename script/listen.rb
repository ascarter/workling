puts '=> Loading Rails...'

require File.dirname(__FILE__) + '/../../../../config/environment'
require File.dirname(__FILE__) + '/../lib/workling/starling/poller'
require File.dirname(__FILE__) + '/../lib/workling/starling/routing/class_and_method_routing'

puts '** Rails loaded.'
puts '** Starting Workling::Starling::Poller...'
puts '** Use CTRL-C to stop.'

client = Workling::Starling::Poller.new(Workling::Starling::Routing::ClassAndMethodRouting.new)

trap(:INT) { exit }

begin
  client.listen
ensure
  puts '** Exiting'
end

def tail(log_file)
  cursor = File.size(log_file)
  last_checked = Time.now
  tail_thread = Thread.new do
    File.open(log_file, 'r') do |f|
      loop do
        f.seek cursor
        if f.mtime > last_checked
          last_checked = f.mtime
          contents = f.read
          cursor += contents.length
          print contents
        end
        sleep 1
      end
    end
  end
  tail_thread
end
