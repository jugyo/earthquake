# encoding: UTF-8
#require 'uri'
#require 'open-uri'

module Earthquake
  module Plugin
    attr_reader :plugin

    def allowed_host?( hostname )
      allowed_hosts = ['gist.github.com']

      allowed_hosts.include? hostname
    end

    def plugin_install( plugin_uri )
      uri = URI.parse( plugin_uri )
      unless uri.host == "gist.github.com"
        puts "The host must be gist.github.com".c(41)
      else
        puts "..."
        return
        gist_id = uri.path[/\d+/]
        meta = JSON.parse(open("https://gist.github.com/api/v1/json/#{gist_id}").read)
        filename = meta["gists"][0]["files"][0]
        raw = open("https://gist.github.com/raw/#{gist_id}/#{filename}").read

        puts '-' * 80
        puts raw.c(36)
        puts '-' * 80

        filename = "#{meta["gists"][0]["repo"]}.rb" if filename =~ /^gistfile/
        filepath = File.join(config[:plugin_dir], filename)
        if confirm("Install to '#{filepath}'?")
          File.open(File.join(config[:plugin_dir], filename), 'w') do |file|
            file << raw
            file << "\n# #{m[1]}"
          end
          reload
        end
      end
    end
  end

  extend Plugin
end
