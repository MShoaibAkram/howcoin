require 'sinatra'
require 'colorize'
require 'active_support/time'
require_relative 'client'
require_relative 'helpers'

PORT, PEER_PORT = ARGV.first(2)
set :port, PORT

STATE = Hash.new
{
}
update_state(PORT => nil)
update_state(PEER_PORT => nil)

COINS = File.readlines("coin.txt").map(&:chomp)
@my_coin = COINS.sample
@version_number = 0
puts "My Coins, now and forever, is #{@my_coin.green}!"

update_state(PORT => [@my_coin, @version_number])

every(8.seconds) do
  puts "Screw #{@my_coin.red}."
  @version_number += 1
  @my_coin = COINS.sample
  update_state(PORT => [@my_coin, @version_number])
  puts "My new Coins are #{@my_coin.green}!"
end

every(3.seconds) do
  STATE.keys.each do |port|
    next if port == PORT
    puts "Fetching update from #{port.to_s.green}"
    begin
      gossip_response = Client.gossip(port, JSON.dump(STATE))
      update_state(JSON.load(gossip_response))
    rescue Faraday::ConnectionFailed => e
      STATE.delete(port)
    end
  end
  render_state
end

# @param state
post '/gossip' do
  their_state = params[:state]
  update_state(JSON.load(their_state))
  JSON.dump(STATE)
end
