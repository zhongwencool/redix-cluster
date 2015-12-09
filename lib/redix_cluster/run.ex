defmodule RedixCluster.Run do
  @moduledoc false

  @type command :: [binary]

  @spec command(command, Keyword.t) :: {:ok, term} |{:error, term}
  def command(command, opts) do
    case RedixCluster.Monitor.get_slot_cache do
     {:cluster, slots_maps, slots, version} ->
        command
        |> parse_key_from_command
        |> key_to_slot_hash
        |> get_pool_by_slot(slots_maps, slots, version)
        |> query_redis_pool(command, :command, opts)
     {:not_cluster, version, pool_name} ->
       query_redis_pool({version, pool_name}, command, :command, opts)
    end
  end

  @spec pipeline([command], Keyword.t) :: {:ok, term} |{:error, term}
  def pipeline(pipeline, opts) do
    case RedixCluster.Monitor.get_slot_cache do
      {:cluster, slots_maps, slots, version} ->
         pipeline
         |> parse_keys_from_pipeline
         |> keys_to_slot_hashs
         |> is_same_slot_hashs
         |> get_pool_by_slot(slots_maps, slots, version)
         |> query_redis_pool(pipeline, :pipeline, opts)
      {:not_cluster, version, pool_name} ->
         query_redis_pool({version, pool_name}, pipeline, :pipeline, opts)
    end
  end

  @spec transaction([command], Keyword.t) :: {:ok, term} |{:error, term}
  def transaction(pipeline, opts) do
    transaction = [["MULTI"]] ++ pipeline ++ [["EXEC"]]
    case RedixCluster.Monitor.get_slot_cache do
      {:cluster, slots_maps, slots, version} ->
         pipeline
         |> parse_keys_from_pipeline
         |> keys_to_slot_hashs
         |> is_same_slot_hashs
         |> get_pool_by_slot(slots_maps, slots, version)
         |> query_redis_pool(transaction, :pipeline, opts)
      {:not_cluster, version, pool_name} ->
         query_redis_pool({version, pool_name}, transaction, :pipeline, opts)
    end
  end

  defp parse_key_from_command([term1, term2|_]), do: verify_command_key(term1, term2)
  defp parse_key_from_command([term]), do: verify_command_key(term, "")
  defp parse_key_from_command(_), do: {:error, :invalid_cluster_command}

  defp parse_keys_from_pipeline(pipeline) do
    case get_command_keys(pipeline) do
      {:error, _} = error -> error
      keys -> for [term1, term2]<- keys, do: verify_command_key(term1, term2)
    end
  end

  defp key_to_slot_hash({:error, _} = error), do: error
  defp key_to_slot_hash(key) do
    case Regex.run(~r/{\S+}/, key) do
      nil -> RedixCluster.Hash.hash(key)
      [tohash_key] ->
        tohash_key
        |> String.strip(?{)
        |> String.strip(?})
        |> RedixCluster.Hash.hash
    end
  end

  defp keys_to_slot_hashs({:error, _} = error), do: error
  defp keys_to_slot_hashs(keys) do
    for key<-keys, do: key_to_slot_hash(key)
  end

  defp is_same_slot_hashs({:error, _} = error), do: error
  defp is_same_slot_hashs([hash|_] = hashs) do
    case Enum.all?(hashs, fn(h) -> h != nil and h == hash end) do
      false -> {:error, :key_must_same_slot}
      true -> hash
    end
  end

  def get_pool_by_slot({:error, _} = error, _, _, _), do: error
  def get_pool_by_slot(slot, slots_maps, slots, version) do
    index = Enum.at(slots, slot)
    cluster = Enum.at(slots_maps, index - 1)
    case cluster == nil or cluster.node == nil do
      true ->  {version, nil}
      false -> {version, cluster.node.pool}
    end
  end

  defp query_redis_pool({:error, _} = error, _command, _opts, _type), do: error
  defp query_redis_pool({version, nil}, _command, _opts, _type) do
    RedixCluster.Monitor.refresh_mapping(version)
    {:error, :retry}
  end
  defp query_redis_pool({version, pool_name}, command, type, opts) do
    try do
      :poolboy.transaction(pool_name, fn(worker) -> GenServer.call(worker, {type, command, opts}) end)
      |> parse_trans_result(version)
    catch
       :exit, _ ->
         RedixCluster.Monitor.refresh_mapping(version)
         {:error, :retry}
    end
  end

  defp parse_trans_result({:error, %Redix.Error{message: <<"MOVED", _redirectioninfo::binary>>}}, version) do
    RedixCluster.Monitor.refresh_mapping(version)
    {:error, :retry}
  end
  defp parse_trans_result({:error, :no_connection}, version) do
    RedixCluster.Monitor.refresh_mapping(version)
    {:error, :retry}
  end
  defp parse_trans_result(payload, _), do: payload

  defp verify_command_key(term1, term2) do
    String.downcase(to_string(term1))
    |> forbid_harmful_command(term2)
  end

  defp forbid_harmful_command("info", _), do: {:error, :invalid_info_command}
  defp forbid_harmful_command("config", _), do: {:error, :invalid_config_command}
  defp forbid_harmful_command("shutdown", _), do: {:error, :invalid_shutdown_command}
  defp forbid_harmful_command("slaveof", _), do: {:error, :invalid_slaveof_command}
  defp forbid_harmful_command(_, key), do: to_string(key)

  defp get_command_keys([["MULTI"]|_]), do: {:error, :must_use_transaction}
  defp get_command_keys(commands), do: make_cmd_key(commands, [])

  defp make_cmd_key([], acc), do: acc
  defp make_cmd_key([[x, y|_]|rest], acc), do: make_cmd_key(rest, [[x, y] | acc])
  defp make_cmd_key([_|rest], acc), do: make_cmd_key(rest, acc)

end