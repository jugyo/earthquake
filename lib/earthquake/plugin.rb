require 'uri'
require 'open-uri'

module Earthquake
  module Plugin
    attr_reader :plugin

    def known_plugin?( plugin_name )
      plugin_list.include? plugin_name
    end

    def plugin_install( uri )
      uri = URI.parse( uri )

      unless config[:only_gists] == false and !allowed_host? uri.host
        case
        when uri.host == 'gist.github.com'
          plugin_install_gist uri
        when uri.scheme == 'file'
          plugin_install_local uri
        else
          puts "Unsupported plugin source".c(41)
        end
      else
        puts "Installing plugins from unapproved sources disallowed".c(41)
        puts "Host must be one of: "+allowed_hosts.join(', ').c(41)
      end
    end

    def plugin_list
      plugins = []
      Dir.entries( config[:plugin_dir] ).each do |filename|
        plugins << filename.sub('.rb','') if filename.end_with? '.rb'
      end
      return plugins
    end

    def plugin_uninstall( name )
#puts ActiveSupport::Dependencies.loaded.class
#ActiveSupport::Dependencies.loaded.each {|d| puts d}
#return
      unless known_plugin? name
        puts "Unknown plugin, \"#{name}\"."
        return false
      end

      if confirm("Really uninstall \"#{name}\"?")
        if File.writable? plugin_path(name)
          ActiveSupport::Dependencies.loaded.delete plugin_path(name).sub('.rb','')
          File.delete plugin_path(name)
          reload
        else
          puts "Unable to delete plugin file."
        end
      else
        puts "Uninstall cancelled"
      end
    end

    def plugin_view( name )
      if known_plugin?(name) and File.readable? plugin_path(name)
        plugin_show_contents File.open( plugin_path(name) ).read
      else
        puts "Unknown or unreadable plugin"
      end
    end

    private

    def allowed_host?( hostname )
      allowed_hosts.include? hostname
    end

    def allowed_hosts
      ['gist.github.com']
    end

    def plugin_install_gist( uri )
      gist_id = uri.path[/\d+/]
      meta = JSON.parse(open("https://gist.github.com/api/v1/json/#{gist_id}").read)
      filename = meta["gists"][0]["files"][0]
      raw = open("https://gist.github.com/raw/#{gist_id}/#{filename}").read

      plugin_show_contents raw

      filename = meta["gists"][0]["repo"] if filename =~ /^gistfile/
      if confirm("Install to '#{plugin_path(filename)}'?")
        plugin_save :filepath => plugin_path(filename),
                    :contents => raw,
                    :source   => "https://gist.github.com/#{gist_id}"
      end
    end

    def plugin_install_local( uri )
      puts "Not implemented"
    end

    def plugin_path( name )
      name = "#{name}.rb" unless name.end_with? '.rb'
      File.join( @config[:plugin_dir], name )
    end

    def plugin_save( plugin )
      File.open( plugin[:filepath], 'w') do |file|
        file << plugin[:contents]
        file << "\n# #{plugin[:source]}"
      end
      reload
    end

    def plugin_show_contents( contents )
      puts '-' * 80
      puts contents.c(36)
      puts '-' * 80
    end
  end

  extend Plugin
end
