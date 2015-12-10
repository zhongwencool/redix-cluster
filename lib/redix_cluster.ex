defmodule RedixCluster do
  @moduledoc """
  This module provides the main API to interface with Redis Cluster by Redix.

  ## Overview

  Module.Func                | Description
  -------------------------- | -----------------------------------
  RedixCluster.start/2       | start redixcluster application
  RedixCluster.command/2     | RedixCluster.command(~w(SET mykey foo))
  RedixCluster.pipeline/2    | RedixCluster.pipeline([~w(SET mykey foo)])
  RedixCluster.transaction/2 | RedixCluster.transaction([~w(SET mykey foo)])

  ## Require

  Make Sure CROSSSLOT `Keys` in request hash to the `same slot`
  ## Examples
      `Same hash keys`
      iex> ~w(mget {user}123 {user}234 {user}456)

      `Diff hash keys`
      iex> ~w(mget {user1}123 {user2}234 {user3}456)
      ["mget", "{user1}123", "{user2}234", "{user3}456"]

  Make sure all char is {} is the same

  """
  use Application

  @type command :: [binary]

  @max_retry 20
  @redis_retry_delay 100

  @doc """
    Starts RedixCluster Application by config.exs
  """
  @spec start(atom, :permanent | :transient | :temporary) :: Supervisor.on_start
  def start(_type, _args), do: RedixCluster.Supervisor.start_link

  @doc """
  `Make sure` CROSSSLOT Keys in request hash to the same slot

  This function works exactly like `Redix.command/3`
  ## Examples

      iex> RedixCluster.command(~w(SET mykey foo))
      {:ok, "OK"}

      iex> RedixCluster.command(~w(GET mykey))
      {:ok, "foo"}

      iex> RedixCluster.command(~w(INCR mykey zhongwen))
      {:error,
       %Redix.Error{message: "ERR wrong number of arguments for 'incr' command"}}

      iex> RedixCluster.command(~w(mget ym d ))
      {:error,
       %Redix.Error{message: "CROSSSLOT Keys in request don't hash to the same slot"}}

      iex> RedixCluster.command(~w(mset {keysamehash}ym 1 {keysamehash}d 2 ))
      {:ok, "OK"}

      iex> RedixCluster.command(~w(mget {keysamehash}ym {keysamehash}d ))
      {:ok, ["1", "2"]}

  """
  @spec command(String.t, Keyword.t) ::
    {:ok, Redix.Protocol.redis_value} |
    {:error, Redix.Error.t | atom}
  def command(command, opts \\[]), do: command(command, opts, 0)

  @doc """
    This function works exactly like `RedixCluster.command/2` but:

    the error will be raised

    ## Examples

      iex> RedixCluster.command!(~w(SET mykey foo))
      "OK"

      iex> RedixCluster.command!(~w(INCR mykey))
      ** (Redix.Error) ERR value is not an integer or out of range
         (redix_cluster) lib/redix_cluster.ex:40: RedixCluster.command!/2

  """
  @spec command!(String.t, Keyword.t) :: Redix.Protocol.redis_value
  def command!(command, opts \\[]) do
    command(command, opts)
    |> parse_error
  end

  @doc """
  `Make sure` CROSSSLOT Keys in request hash to the same slot

  This function works exactly like `Redix.pipeline/3`

  ## Examples

      iex> RedixCluster.pipeline([~w(INCR mykey), ~w(INCR mykey), ~w(DECR mykey)])
      {:ok, [1, 2, 1]}

      iex> RedixCluster.pipeline([~w(SET {samehash}k3 foo), ~w(INCR {samehash}k2), ~w(GET {samehash}k1)])
      {:ok, ["OK", 1, nil]}

      iex> RedixCluster.pipeline([~w(SET {diffhash3}k3 foo), ~w(INCR {diffhash2}k2), ~w(GET {diffhash1}k1)])
      {:error, :key_must_same_slot}

  """
  @spec pipeline([command], Keyword.t) ::
     {:ok, [Redix.Protocol.redis_value]} |
     {:error, atom}
  def pipeline(commands, opts\\ []), do: pipeline(commands, opts, 0)

  @doc """
  `Make sure` CROSSSLOT Keys in request hash to the same slot

  This function works exactly like `RedixCluster.pipeline/2` but

  the error will be raised

  ## Examples

      iex> RedixCluster.pipeline!([~w(INCR mykey), ~w(INCR mykey), ~w(DECR mykey)])
      {:ok, [1, 2, 1]}

      iex> RedixCluster.pipeline!([~w(SET {samehash}k3 foo), ~w(INCR {samehash}k2), ~w(GET {samehash}k1)])
      {:ok, ["OK", 1, nil]}

      iex> RedixCluster.pipeline!([~w(SET {diffhash3}k3 foo), ~w(INCR {diffhash2}k2), ~w(GET {diffhash1}k1)])
      ** (RedixCluster.Error) CROSSSLOT Keys in request don't hash to the same slot
          (redix_cluster) lib/redix_cluster.ex:215: RedixCluster.parse_error/1

  """
  @spec pipeline!([command], Keyword.t) :: [Redix.Protocol.redis_value]
  def pipeline!(commands, opts\\ []) do
    pipeline(commands, opts)
    |> parse_error
  end

  @doc """
  `Make sure` CROSSSLOT Keys in request hash to the same slot

  ## Examples

      iex> RedixCluster.transaction([~w(set mykey 1), ~w(INCR mykey), ~w(INCR mykey), ~w(DECR mykey)])
      {:ok, ["OK", "QUEUED", "QUEUED", "QUEUED", "QUEUED", ["OK", 2, 3, 2]]}

      iex> RedixCluster.transaction([~w(SET {samehash}k3 foo), ~w(INCR {samehash}k2), ~w(GET {samehash}k1)])
      {:ok, ["OK", "QUEUED", "QUEUED", "QUEUED", ["OK", 2, nil]]}
  """
  @spec transaction([command], Keyword.t) ::
    {:ok, [Redix.Protocol.redis_value]} | {:error, term}
  def transaction(commands, opts\\ []), do: transaction(commands, opts, 0)

  @doc """
  `Make sure` CROSSSLOT Keys in request hash to the same slot

  ## Examples

      iex> RedixCluster.transaction!([~w(set mykey 1), ~w(INCR mykey), ~w(INCR mykey), ~w(DECR mykey)])
      {:ok, ["OK", "QUEUED", "QUEUED", "QUEUED", "QUEUED", ["OK", 2, 3, 2]]}

      iex> RedixCluster.transaction!([~w(SET {samehash}k3 foo), ~w(INCR {samehash}k2), ~w(GET {samehash}k1)])
      {:ok, ["OK", "QUEUED", "QUEUED", "QUEUED", ["OK", 2, nil]]}

      iex> RedixCluster.transaction!([~w(SET {diffhash3}k3 foo), ~w(INCR {diffhash2}k2), ~w(GET {diffhash1}k1)])
      ** (RedixCluster.Error) CROSSSLOT Keys in request don't hash to the same slot
          (redix_cluster) lib/redix_cluster.ex:215: RedixCluster.parse_error/1

  """
  @spec transaction!([command], Keyword.t) :: [Redix.Protocol.redis_value]
  def transaction!(commands, opts\\ []) do
    transaction(commands, opts)
    |> parse_error
  end

  # whenever the application is updated.
  def config_change(_changed, _new, _removed), do: :ok

  defp command(_command, _opts, count) when count >= @max_retry, do: {:error, :no_connection}
  defp command(command, opts, count) do
    unless count==0, do: :timer.sleep(@redis_retry_delay)
    RedixCluster.Run.command(command, opts)
    |> need_retry(command, opts, count, :command)
  end

  defp pipeline(_commands, _opts, count) when count >= @max_retry, do: {:error, :no_connection}
  defp pipeline(commands, opts, count) do
    unless count==0, do: :timer.sleep(@redis_retry_delay)
    RedixCluster.Run.pipeline(commands, opts)
    |> need_retry(commands, opts, count, :pipeline)
  end

  defp transaction(_commands, _opts, count) when count >= @max_retry, do: {:error, :no_connection}
  defp transaction(commands, opts, count) do
    unless count==0, do: :timer.sleep(@redis_retry_delay)
    RedixCluster.Run.transaction(commands, opts)
    |> need_retry(commands, opts, count, :transaction)
  end

  defp need_retry({:error, :retry}, command, opts, count, :command), do: command(command, opts, count+1)
  defp need_retry({:error, :retry}, commands, opts, count, :pipeline), do: pipeline(commands, opts, count+1)
  defp need_retry({:error, :retry}, commands, opts, count, :transaction), do: transaction(commands, opts, count+1)
  defp need_retry(result, _command, _count, _opts, _type), do: result

  defp parse_error({:ok, result}), do: result
  defp parse_error({:error, %Redix.Error{} = error}), do: raise error
  defp parse_error({:error, reason}), do: raise RedixCluster.Error, reason

end