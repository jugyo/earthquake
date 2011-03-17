require 'json'
require 'thread'
require 'readline'
require 'bundler/setup'
Bundler.require :default

module Earthquake
  extend ActiveSupport::Autoload

  Dir[File.join(File.dirname(__FILE__), 'earthquake', '**', '*.rb')].each do |filename|
    autoload File.basename(filename, '.rb').camelize.to_sym
  end

  extend Core
  extend Output
  extend Input
  extend GetAccessToken
  extend Twitter
end
