defmodule ExredisCluster do
  use Application

  @max_retry 20
  @redis_retry_delay 100

  def start(_type, _args), do: RedisCluster.Supervisor.start_link

  def command(command, opts \\[]), do: command(command, opts, 0)

  def command!(command, opts \\[]) do
    case command(command, opts, 0) do
      {:ok, resp} -> resp
      {:error, error} -> raise error
    end
  end

  def pipeline(commands, opts\\ []), do: pipeline(commands, opts, 0)

  def pipeline!(commands, opts\\ []) do
    case pipeline(commands, opts, 0) do
      {:error, error} -> raise error
      {:ok, resps} -> Enum.map(resps, &parse_error/1)
    end
  end

  def transaction(commands, opts\\ []), do: transaction(commands, opts, 0)

  def transaction!(commands, opts\\ []) do
    case transaction(commands, opts, 0) do
      {:error, error} -> raise error
      {:ok, resps} -> Enum.map(resps, &parse_error/1)
    end
  end

  # whenever the application is updated.
  def config_change(_changed, _new, _removed), do: :ok

  defp command(_command, _opts, count) when count >= @max_retry, do: {:error, :no_connection}
  defp command(command, opts, count) do
    unless count==0, do: :timer.sleep(@redis_retry_delay)
    RedisCluster.Run.command(command, opts)
    |> need_retry(command, opts, count, :command)
  end

  defp pipeline(_commands, _opts, count) when count >= @max_retry, do: {:error, :no_connection}
  defp pipeline(commands, opts, count) do
    unless count==0, do: :timer.sleep(@redis_retry_delay)
    RedisCluster.Run.pipeline(commands, opts)
    |> need_retry(commands, opts, count, :pipeline)
  end

  defp transaction(_commands, _opts, count) when count >= @max_retry, do: {:error, :no_connection}
  defp transaction(commands, opts, count) do
    unless count==0, do: :timer.sleep(@redis_retry_delay)
    RedisCluster.Run.transaction(commands, opts)
    |> need_retry(commands, opts, count, :transaction)
  end

  defp need_retry({:error, :retry}, command, opts, count, :command), do: command(command, opts, count+1)
  defp need_retry({:error, :retry}, commands, opts, count, :pipeline), do: pipeline(commands, opts, count+1)
  defp need_retry({:error, :retry}, commands, opts, count, :transaction), do: transaction(commands, opts, count+1)
  defp need_retry(result, _command, _count, _opts, _type), do: result

  defp parse_error(%Redix.Error{} = error), do: raise error
  defp parse_error(res), do: res

end
