#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'twitter' 
require 'yaml'

config = YAML::load_file('config.yml')
fc = config.first
username = fc['username']

puts "\nDELETING TWEETS FOR: #{username}"
puts "(Ctrl-C to stop)\n\n"
 
Twitter.configure do |config|
  config.consumer_key       = fc['consumer_key']
  config.consumer_secret    = fc['consumer_secret']
  config.oauth_token        = fc['oauth_token']
  config.oauth_token_secret = fc['oauth_secret']
end

t_id = 0
while t_id != nil do
  t_id = nil
  tweets = Twitter.user_timeline(username, {
      :count => 200, 
      :include_entities => true, 
      :trim_user => true, 
      :include_rts => true
    }
  )
  puts "statuses=#{tweets.length}"
  if tweets.length == 0
    t_id = 1
    puts "Sleeping for 10 minutes..."
    sleep (60*10)
  end
  tweets.each do |t|
    #puts t.inspect
    #next unless t.reply?
    t_id = t['id']
    begin 
      if Twitter.status_destroy(t_id)
        puts "D: #{t['text']}"
      else
        puts "\n!!! #{t_id}\n"
      end
    rescue Twitter::Error::ClientError => e
      puts e.message
      sleep 5
    rescue Twitter::Error::NotFound => e
      puts e.message
      sleep 5
    end
  end
end