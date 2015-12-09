defmodule RedixCluster.Pools.Supervisor do
  @moduledoc false
  
  use Supervisor
  use RedixCluster.Helper

  @default_pool_size 10
  @default_pool_max_overflow 0
  @max_retry 20

  @spec start_link(Keyword.t) :: Supervisor.on_start
  def start_link(options) do
    :ets.new(__MODULE__, [:set, :named_table, :public])
    Supervisor.start_link(__MODULE__, nil, options)
  end

  def init(nil), do: {:ok, {{:one_for_one, 1, 5}, []}}

  @spec new_pool(char_list, integer) :: {:ok, atom}|{:error, atom}
  def new_pool(host, port) do
    pool_name = Enum.join(["Pool", host, ":", port]) |> String.to_atom
    case Process.whereis(pool_name) do
      nil ->
        :ets.insert(__MODULE__, {pool_name,0})
        pool_size = get_env(:pool_size, @default_pool_size)
       	pool_max_overflow = get_env(:pool_max_overflow, @default_pool_max_overflow)
        pool_args = [name: {:local, pool_name},
                     worker_module: RedixCluster.Worker,
                     size: pool_size,
                     max_overflow: pool_max_overflow]
        worker_args = [host: host, port: port, pool_name: pool_name]
        child_spec = :poolboy.child_spec(pool_name, pool_args, worker_args)
        {result, _} = Supervisor.start_child(__MODULE__, child_spec)
        {result, pool_name};
      _ -> {:ok, pool_name}
    end
  end

  @spec register_worker_connection(String.t) :: :ok
  def register_worker_connection(pool_name) do
    restart_counter = :ets.update_counter(__MODULE__, pool_name, 1)
    unless restart_counter < @max_retry, do: stop_redis_pool(pool_name)
    :ok
  end

  @spec stop_redis_pool(String.t) ::
  :ok | {:error, error} when error: :not_found | :simple_one_for_one | :running | :restarting
  def stop_redis_pool(pool_name) do
    Supervisor.terminate_child(__MODULE__, pool_name)
    Supervisor.delete_child(__MODULE__, pool_name)
  end

end