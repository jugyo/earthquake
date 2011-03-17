require 'json'
require 'thread'
require 'readline'
require 'bundler/setup'
Bundler.require :default

module Earthquake
  def self.reload
    ActiveSupport::Dependencies.clear
    Dir[File.join(File.dirname(__FILE__), 'earthquake', '**', '*.rb')].each do |filename|
      require_dependency filename
    end
  end

  reload

  extend Earthquake::Core
  extend Earthquake::Output
  extend Earthquake::Input
  extend Earthquake::GetAccessToken
  extend Earthquake::Twitter

  command :exit do |m|
    stop
  end

  command :help do |m|
    puts "TODO..."
  end

  command :restart do |m|
    puts 'restarting...'
    exec File.expand_path('../../bin/earthquake', __FILE__)
  end

  command :eval do |m|
    ap eval(m[1])
  end

  command %r|^[^/]+| do |m|
    twitter.update(m[0])
  end

  command %r|^/reply (\d+)\s+(.*)|, :as => :reply do |m|
    # TODO
    ap m
  end

  command :status do |m|
    puts_status twitter.status(m[1])
  end

  command :delete do |m|
    twitter.status_destroy(m[1])
  end

  command :retweet do |m|
    twitter.retweet(m[1])
  end

  command :favorite do |m|
    twitter.favorite(m[1])
  end

  command :unfavorite do |m|
    twitter.unfavorite(m[1])
  end
end
