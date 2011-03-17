require 'json'
require 'thread'
require 'readline'
require 'bundler/setup'
Bundler.require :default

%w(
core
output
input
get_access_token
twitter
).each { |name| require "earthquake/#{name}" }
