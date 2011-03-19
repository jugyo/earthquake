%w(
  json
  thread
  readline
  active_support/core_ext
  active_support/dependencies
  twitter/json_stream
  notify
  ap
  launchy
  oauth
  twitter_oauth
  termcolor
).each { |lib| require lib }

%w(
  ext
  core
  output
  input
  get_access_token
  twitter
  commands
).each { |name| require_dependency File.expand_path("../earthquake/#{name}", __FILE__) }

Thread.abort_on_exception = true