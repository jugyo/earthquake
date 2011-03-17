require 'json'
require 'thread'
require 'readline'
require 'bundler/setup'
Bundler.require :default

Dir[File.join(File.dirname(__FILE__), 'earthquake', '**', '*.rb')].each do |filename|
  require filename
end

module Earthquake
  extend Earthquake::Core
  extend Earthquake::Output
  extend Earthquake::Input
  extend Earthquake::GetAccessToken

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
end
