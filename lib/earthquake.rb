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
    insert do
      puts "TODO..."
    end
  end
end
