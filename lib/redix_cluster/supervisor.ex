defmodule RedixCluster.Supervisor do
  @moduledoc false

  import Supervisor.Spec

  @spec start_link() :: Supervisor.on_start
  def start_link() do
  children = [
    supervisor(RedixCluster.Pools.Supervisor, [[name: RedixCluster.Pools.Supervisor]], [modules: :dynamic]),
    worker(RedixCluster.Monitor, [[name: RedixCluster.Monitor]], [modules: :dynamic])
  ]
  Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end

end
