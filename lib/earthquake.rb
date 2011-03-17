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
end
