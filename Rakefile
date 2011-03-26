require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "earthquake"
  gem.homepage = "http://github.com/jugyo/earthquake"
  gem.license = "MIT"
  gem.summary = %Q{Twitter Client on Terminal.}
  gem.description = %Q{Twitter Client on Terminal with Twitter Streaming API.}
  gem.email = "jugyo.org@gmail.com"
  gem.authors = ["jugyo"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  gem.add_runtime_dependency 'jabber4r', '> 0.1'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'
  gem.post_install_message = %{
The Application info as Twitter Client has been updated at 2011-03-20 15:00:00 UTC.
Accordingly that, You should renew the access token if it is old.

1) In ~/.earthquake/config, remove these lines:

    Earthquake.config[:token] = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    Earthquake.config[:secret] = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'

2) Launch earthquake:

    $ earthquake

}
  gem.required_ruby_version = Gem::Requirement.new(">= 1.9.1")
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "earthquake #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
