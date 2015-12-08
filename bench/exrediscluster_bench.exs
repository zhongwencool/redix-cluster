defmodule BaseBench do
  use Benchfella


  setup_all do
    Application.ensure_all_started(:exredis_cluster)
    Application.ensure_all_started(:eredis_cluster)
    context =
      %{
        exredis_cluster: :exredis_cluster,
        eredis_cluster: :eredis_cluster,
        cmds: make_random_cmds,
        pipelines: make_random_pipelines,
        transactions: make_random_transactions,
      }
    {:ok, context}
  end

  teardown_all _ do
    ExredisCluster.command(~w(del {user_slota}*))
    ExredisCluster.command(~w(del {user_slotb}*))
    ExredisCluster.command(~w(del {user_slotc}*))
    ExredisCluster.command(~w(del {user_slotd}*))
    Application.stop(:exredis_cluster)
    Application.stop(:eredis_cluster)
  end

  before_each_bench context do
    {:ok, context}
  end

  after_each_bench _ do
    :ok
  end

  bench "[Ex] command", [cmds: bench_context[:cmds]] do
    for cmd <- cmds, do: ExredisCluster.command(cmd)
  end

  bench "[Erl] command", [cmds: bench_context[:cmds]] do
    for cmd <- cmds, do: :eredis_cluster.q(cmd)
  end

  bench "[Ex] pipeline", [pipelines: bench_context[:pipelines]] do
    for pipeline <- pipelines, do: ExredisCluster.pipeline(pipeline)
  end

  bench "[Erl] pipeline", [pipelines: bench_context[:pipelines]] do
    for pipeline <- pipelines, do: :eredis_cluster.qp(pipeline)
  end

  bench "[Ex] transactions", [transactions: bench_context[:transactions]] do
    for transaction <- transactions, do: ExredisCluster.transaction(transaction)
  end

  bench "[Erl] transactions", [transactions: bench_context[:transactions]] do
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
    List.duplicate(slota, 1000) ++ List.duplicate(slotb, 1000) ++ List.duplicate(slotc, 1000) ++ List.duplicate(slotd, 1000)
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
    List.duplicate(slota, 1000) ++ List.duplicate(slotb, 1000) ++ List.duplicate(slotc, 1000) ++ List.duplicate(slotd, 1000)
  end

end
