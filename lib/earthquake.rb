require 'json'
require 'thread'
require 'readline'
require 'bundler/setup'
Bundler.require :default

$:.unshift File.expand_path('..', __FILE__)

require 'earthquake/core'

module Earthquake
  extend Earthquake::Core
end
