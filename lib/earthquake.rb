require 'json'
require 'thread'
require 'readline'
require 'bundler/setup'
Bundler.require :default

$:.unshift File.expand_path('..', __FILE__)
require 'earthquake/core'

# TODO: command completion
# TODO: command system
# TODO: filter system
# TODO: colorize
# TODO: setup Twitter client to post and etc
# TODO: reconnect

module Earthquake
  extend Earthquake::Core
end
