defmodule BaseBench do
  use Benchfella


  setup_all do
    Application.ensure_all_started(:redix_cluster)
    Application.ensure_all_started(:eredis_cluster)
    context =
      %{
        redix_cluster: :redix_cluster,
        eredis_cluster: :eredis_cluster,
        cmds: make_random_cmds,
        pipelines: make_random_pipelines,
        transactions: make_random_transactions,
      }
    {:ok, context}
  end

  teardown_all _ do
    RedixCluster.command(~w(del {user_slota}*))
    RedixCluster.command(~w(del {user_slotb}*))
    RedixCluster.command(~w(del {user_slotc}*))
    RedixCluster.command(~w(del {user_slotd}*))
    Application.stop(:redix_cluster)
    Application.stop(:eredis_cluster)
  end

  before_each_bench context do
    {:ok, context}
  end

  after_each_bench _ do
    :ok
  end

  bench "[Redix]cmd", [cmds: bench_context[:cmds]] do
    for cmd <- cmds, do: RedixCluster.command(cmd)
  end

  bench "[Redis]cmd", [cmds: bench_context[:cmds]] do
    for cmd <- cmds, do: :eredis_cluster.q(cmd)
  end

  bench "[Redix]pipe", [pipelines: bench_context[:pipelines]] do
    for pipeline <- pipelines, do: RedixCluster.pipeline(pipeline)
  end

  bench "[Eredis]pipe", [pipelines: bench_context[:pipelines]] do
    for pipeline <- pipelines, do: :eredis_cluster.qp(pipeline)
  end

  bench "[Redix]trans", [transactions: bench_context[:transactions]] do
    for transaction <- transactions, do: RedixCluster.transaction(transaction)
  end

  bench "[Eredis]trans", [transactions: bench_context[:transactions]] do
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
