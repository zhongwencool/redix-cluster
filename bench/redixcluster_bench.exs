defmodule BaseBench do
  use Benchfella


  setup_all do
    Application.ensure_all_started(:redix_cluster)
    Application.ensure_all_started(:eredis_cluster)
    context =
      %{
        cmds: make_random_cmds,
        pipelines: make_random_pipelines,
        transactions: make_random_transactions,
      }
    {:ok, context}
  end

  teardown_all context do
    clear_all_key(context)
    # wait for all keys in the pool will be deleted
    :timer.sleep(3000)
    Application.stop(:redix_cluster)
    Application.stop(:eredis_cluster)
  end

  before_each_bench context do
    {:ok, context}
  end

  after_each_bench _ do
    :ok
  end

  bench "Excmd", [cmds: bench_context[:cmds]] do
    for cmd <- cmds, do: RedixCluster.command(cmd)
  end

  bench "Ecmd", [cmds: bench_context[:cmds]] do
    for cmd <- cmds, do: :eredis_cluster.q(cmd)
  end

  bench "Expipe", [pipelines: bench_context[:pipelines]] do
    for pipeline <- pipelines, do: RedixCluster.pipeline(pipeline)
  end

  bench "Epipe", [pipelines: bench_context[:pipelines]] do
    for pipeline <- pipelines, do: :eredis_cluster.qp(pipeline)
  end

  bench "Extrans", [transactions: bench_context[:transactions]] do
    for transaction <- transactions, do: RedixCluster.transaction(transaction)
  end

  bench "Etrans", [transactions: bench_context[:transactions]] do
    for transaction <- transactions, do: :eredis_cluster.transaction(transaction)
  end

# todo
  defp make_random_cmds do
    slota = Enum.map(1..1000, fn(_) ->
                              val = :random.uniform 10000
                              ~w(SET {user_slota}#{val} #{val}) end)
    slotb = Enum.map(1..1000, fn(_) ->
                              val = :random.uniform 10000
                              ~w(SET {user_slotb}#{val} #{val}) end)
    slotc = Enum.map(1..1000, fn(_) ->
                              val = :random.uniform 10000
                              ~w(SET {user_slotc}#{val} #{val}) end)
    slotd = Enum.map(1..1000, fn(_) ->
                              val = :random.uniform 10000
                              ~w(SET {user_slotd}#{val} #{val}) end)
    slota ++ slotb ++ slotc ++ slotd
  end

# todo
  defp make_random_pipelines do
    slota = Enum.map(1..50, fn(_) ->
                              val = :random.uniform 10000
                              ~w(GET {user_slota}#{val}) end)
    slotb = Enum.map(1..50, fn(_) ->
                              val = :random.uniform 10000
                              ~w(GET {user_slotb}#{val}) end)
    slotc = Enum.map(1..50, fn(_) ->
                              val = :random.uniform 10000
                              ~w(GET {user_slotc}#{val}) end)
    slotd = Enum.map(1..50, fn(_) ->
                              val = :random.uniform 10000
                              ~w(GET {user_slotd}#{val}) end)
    List.duplicate(slota, 1000) ++ List.duplicate(slotb, 1000)
    ++ List.duplicate(slotc, 1000) ++ List.duplicate(slotd, 1000)
  end

# todo
  defp make_random_transactions do
    slota = Enum.map(1..50, fn(_) ->
                              val = :random.uniform 10000
                              ~w(GET {user_slota}#{val}) end)
    slotb = Enum.map(1..50, fn(_) ->
                              val = :random.uniform 10000
                              ~w(GET {user_slotb}#{val}) end)
    slotc = Enum.map(1..50, fn(_) ->
                              val = :random.uniform 10000
                              ~w(GET {user_slotc}#{val}) end)
    slotd = Enum.map(1..50, fn(_) ->
                              val = :random.uniform 10000
                              ~w(GET {user_slotd}#{val}) end)
    List.duplicate(slota, 1000) ++ List.duplicate(slotb, 1000)
    ++ List.duplicate(slotc, 1000) ++ List.duplicate(slotd, 1000)
  end

  defp clear_all_key(context) do
  %{
    cmds: cmds,
    pipelines: pipelines,
    transactions: transactions,
   } = context
   Enum.each(cmds, fn([_, key|_]) -> RedixCluster.command(~w(DEL #{key})) end)
   :timer.sleep(600)
   Enum.each(pipelines, fn(pipeline) ->
     for cmds<- pipeline do
       new_cmds = Enum.map(cmds, fn([_, key|_]) -> ~w(DEL #{key}) end)
       RedixCluster.pipeline(new_cmds)
     end
   end)
   :timer.sleep(600)
   Enum.each(transactions, fn(tran) ->
     for cmds<- tran do
       new_cmds = Enum.map(cmds, fn([_, key|_]) -> ~w(DEL #{key}) end)
       RedixCluster.transaction(new_cmds)
       end
   end)
  end

end
