defmodule RedixCluster.Worker do
  @moduledoc """
    role: poolboy worker
  """
  use GenServer
  use RedixCluster.Helper

  def start_link(args), do: GenServer.start_link(__MODULE__, args)

  def init(worker) do
   socket_opts = get_env(:socket_opts, [])
   backoff = get_env(:backoff, 2000)
   max_reconnection_attempts = get_env(:max_reconnection_attempts)
   :erlang.process_flag(:trap_exit, true)
   RedixCluster.Pools.Supervisor.register_worker_connection(worker[:pool_name])
   result = Redix.start_link([host: worker[:host], port: worker[:port]],
     [socket_opts: socket_opts, backoff: backoff, max_reconnection_attempts: max_reconnection_attempts])
   :erlang.process_flag(:trap_exit, false)
   case result do
     {:ok, connection} -> {:ok, %{conn: connection}}
      _ -> {:ok, %{conn: :no_connection}}
   end
  end

  def handle_call({_, _, _}, _from, %{conn: :no_connection} = state) do
    {:reply, {:error, :no_connection}, state}
  end
  def handle_call({:command, params, opts}, _From, %{conn: conn} = state) do
    {:reply, Redix.command(conn, params, opts), state}
  end
  def handle_call({:pipeline, params, opts}, _from, %{conn: conn} = state) do
    {:reply, Redix.pipeline(conn, params, opts), state}
  end
  def handle_call(_request, _from, state), do: {:reply, :ok, state}

  def handle_cast(_msg, state), do: {:noreply, state}

  def handle_info(_request, state), do: {:noreply, state}

  def terminate(_reason, %{conn: nil}), do: :ok
  def terminate(_reason, %{conn: conn}), do: Redix.stop(conn)

end