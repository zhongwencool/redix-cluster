ESpec.start

ESpec.configure fn(config) ->
  config.before fn ->
    {:shared, count: 1}
  end

  config.finally fn(shared) ->

  end
end
