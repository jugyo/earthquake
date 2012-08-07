# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "earthquake/version"

Gem::Specification.new do |s|
  s.name        = "earthquake"
  s.version     = Earthquake::VERSION
  s.authors     = ["jugyo"]
  s.email       = ["jugyo.org@gmail.com"]
  s.homepage    = "https://github.com/jugyo/earthquake"
  s.summary     = %q{Terminal Twitter Client}
  s.description = %q{Twitter Client on Terminal with Twitter Streaming API.}

  s.rubyforge_project = "earthquake"

  s.files         = `git ls-files`.split("\n") + ['consumer.yml']
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "twitter-stream"
  s.add_runtime_dependency "notify"
  s.add_runtime_dependency "i18n"
  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "awesome_print"
  s.add_runtime_dependency "launchy"
  s.add_runtime_dependency "oauth"
  s.add_runtime_dependency "twitter_oauth", "= 0.4.3"
  s.add_runtime_dependency "slop", "~> 3.0"
  s.add_development_dependency "rspec", "~> 2.0"
  s.add_development_dependency "bundler"

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
