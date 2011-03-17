require 'json'
require 'thread'
require 'readline'
require 'bundler/setup'
Bundler.require :default

Thread.abort_on_exception = true

%w(
  core
  output
  input
  get_access_token
  twitter
).each { |name| require_dependency File.expand_path("../earthquake/#{name}", __FILE__) }
