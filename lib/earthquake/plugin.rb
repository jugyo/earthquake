# encoding: UTF-8
#require 'uri'
#require 'open-uri'

module Earthquake
  module Plugin
    attr_reader :plugin

    def allowed_host?( hostname )
      self.allowed_hosts.include? hostname
    end

    def allowed_hosts
      ['gist.github.com']
    end

    def plugin_install( plugin_uri )
      uri = URI.parse( plugin_uri )

      if config[:restrict_plugin_source] and !allowed_host? uri.host
        puts "Installing plugins from unapproved sources disallowed".c(41)
        puts "Host must be one of: "+self.allowed_hosts.join(', ').c(41)
      else
        case
          when uri.host == 'gist.github.com'
            self.plugin_install_gist uri
          else
            puts "Unsupported plugin source type".c(41)
        end
      end
    end

    private

    def plugin_install_gist( uri )
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

  extend Plugin
end
