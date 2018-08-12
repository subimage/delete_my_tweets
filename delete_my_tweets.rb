#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'twitter'
require 'yaml'

class DeleteMyTweets
  def initialize
    yaml_config = YAML::load_file('config.yml')
    config = yaml_config.first
    @username = config['username']
    @num_times_slept = 0
    @delete_words = config['search_words_to_delete']
    @delete_words ||= []

    puts "\nDELETING TWEETS FOR: #{@username}"
    puts "(Ctrl-C to stop)\n\n"

    Twitter.configure do |config|
      config.consumer_key       = config['consumer_key']
      config.consumer_secret    = config['consumer_secret']
      config.oauth_token        = config['oauth_token']
      config.oauth_token_secret = config['oauth_secret']
    end
  end

  def run
    tweet_id = 0
    while tweet_id != nil && 1 >= @num_times_slept do
      tweet_id = nil
      fetch_tweets
      puts "statuses=#{@tweets.length}"
      if @tweets.length == 0
        tweet_id = 1
        wait_for_api
      else
        tweet_id = destroy_tweets
      end
    end
  end

  def fetch_tweets
    @tweets = Twitter.user_timeline(@username, {
        :count => 200,
        :include_entities => true,
        :trim_user => true,
        :include_rts => true
      }
    )
  end

  def destroy_tweets
    last_tweet_id = nil
    @tweets.each do |t|
      #puts t.inspect
      if @delete_words.length > 0
        found_keyword_to_delete = false
        match_text = t['text'].downcase
        if t.attrs[:quoted_status]
          match_text += ' ' + t.attrs[:quoted_status][:text].downcase
        end
        @delete_words.each do |w|
          if match_text.include?(w)
            found_keyword_to_delete = true
            break
          end
        end
        # only delete tweets with keywords
        next unless found_keyword_to_delete
      end
      last_tweet_id = t['id']
      begin
        if Twitter.status_destroy(last_tweet_id)
          puts "D: #{t['text']}"
        else
          puts "\n!!! #{last_tweet_id}\n"
        end
      rescue Twitter::Error::ClientError => e
        puts e.message
        sleep 5
      rescue Twitter::Error::NotFound => e
        puts e.message
        sleep 5
      end
    end
    return last_tweet_id
  end

  def wait_for_api
    puts "No more tweets to delete..."
    puts "Sleeping for 10 minutes to see if we can find more."
    puts "(CTRL-C to exit)\n"
    @num_times_slept += 1
    sleep (60*10)
  end

end

DeleteMyTweets.new.run
