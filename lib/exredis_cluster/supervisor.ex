defmodule RedisCluster.Supervisor do
  @moduledoc false

  import Supervisor.Spec

  def start_link() do
  children = [
    supervisor(RedisCluster.Pools.Supervisor, [[name: RedisCluster.Pools.Supervisor]], [modules: :dynamic]),
    worker(RedisCluster.Monitor, [[name: RedisCluster.Monitor]], [modules: :dynamic])
  ]
  Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end

end