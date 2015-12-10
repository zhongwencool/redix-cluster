defmodule RedixCluster.RefreshCache.Spec do
  use ESpec

  before do
    allow Redix |> to accept :start_link, fn(_, _) -> {:ok, self} end, [:non_strict, :unstick]
    allow Redix |> to accept :stop, fn(_) -> :ok end, [:non_strict, :unstick]
    allow Redix |> to accept :command, fn
      (_, ~w(CLUSTER SLOTS), _) ->
        case get_version do
          1 -> {:ok,
                  [[10923, 16383, ["10.1.2.5", 7000], ["10.1.2.5", 7001]],
                   [5461, 10922, ["10.1.2.6", 7000], ["10.1.2.7", 7001]],
                   [0, 5460, ["10.1.2.7", 7000], ["10.1.2.6", 7001]]]}
          _ -> {:ok,
                  [[10000, 16383, ["10.1.2.5", 7000], ["10.1.2.5", 7001]],
                  [50001, 9999, ["10.1.2.6", 7000], ["10.1.2.7", 7001]],
                  [0, 5000, ["10.1.2.7", 7000], ["10.1.2.6", 7001]]]}
       end
      (_, ~w(set a test), _) ->
        case get_version do
          1 -> {:error, %Redix.Error{message: "MOVED 15495 10.1.2.5:7000"}}
          _ -> {:ok, "OK"}
        end
      (_, ~w(get a), _) -> {:ok, "test"}
    end, [:non_strict, :unstick]

    Application.ensure_all_started(:redix_cluster)
    {:shared, count:  1}
  end

  finally do: {:shared, count: shared.count + 1}

  context "refresh cache test" do
    it do: expect refresh_test |> to eq {{:ok, "OK"}, 1, 2}
  end

  defp refresh_test do
    old = get_version
    result = RedixCluster.command(~w(set a test))
    new = get_version
    {result, old, new}
  end

  defp get_version() do
    case RedixCluster.Monitor.get_slot_cache do
      {:not_cluster, version, _} -> version
      {:cluster, _, _, version} -> version
    end
  end

end
