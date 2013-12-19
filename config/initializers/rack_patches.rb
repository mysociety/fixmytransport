# Workaround for incorrect counting of the keyspace in nested params in rack
# https://github.com/rack/rack/pull/321
# https://github.com/rack/rack/issues/318
if Rack::Utils.respond_to?("key_space_limit=")
  Rack::Utils.key_space_limit = 2622144
end
