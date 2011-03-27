%w(
  json
  thread
  readline
  active_support/core_ext
  active_support/dependencies
  active_support/cache
  twitter/json_stream
  notify
  ap
  launchy
  oauth
  twitter_oauth
).each { |lib| require lib }

%w(
  ext
  core
  cache
  output
  input
  get_access_token
  twitter
  commands
  id_var
).each { |name| require_dependency File.expand_path("../earthquake/#{name}", __FILE__) }

Thread.abort_on_exception = true