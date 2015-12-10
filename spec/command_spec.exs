defmodule RedixCluster.Command.Spec do
  use ESpec

  before do
    allow Redix |> to accept :start_link, fn(_, _) -> {:ok, self} end, [:non_strict, :unstick]
    allow Redix |> to accept :stop, fn(_) -> :ok end, [:non_strict, :unstick]
    allow Redix |> to accept :command, fn
      (_, ~w(CLUSTER SLOTS), _) -> {:ok,
                                 [[10923, 16383, ["10.1.2.5", 7000], ["10.1.2.5", 7001]],
                                  [5461, 10922, ["10.1.2.6", 7000], ["10.1.2.7", 7001]],
                                  [0, 5460, ["10.1.2.7", 7000], ["10.1.2.6", 7001]]]}
      (_, ~w(set a test), _) -> {:ok, "OK"}
      (_, ~w(get a), _) -> {:ok, "test"}
      (_, ~w(incr a), _) -> {:error, %Redix.Error{message: "ERR value is not an integer or out of range"}}
    end, [:non_strict, :unstick]

    Application.ensure_all_started(:redix_cluster)
    {:shared, count: 1} #saves {:key, :value} to `shared`
  end

  finally do: {:shared, answer: shared.count + 1}

  context "command test" do
    it do: expect RedixCluster.command(~w(set a test)) |> to eq {:ok, "OK"}
    it do: expect RedixCluster.command(~w(get a)) |> to eq {:ok, "test"}
    it do: expect RedixCluster.command(~w(incr a)) |> to eq {:error, %Redix.Error{message: "ERR value is not an integer or out of range"}}
  end

  context "command! test" do
    it do: expect RedixCluster.command!(~w(set a test)) |> to eq "OK"
    it do: expect RedixCluster.command!(~w(get a)) |> to eq "test"
    it do
      action = fn() -> RedixCluster.command!(~w(incr a)) end
      expect  action |> to raise_exception Redix.Error, "ERR value is not an integer or out of range"
    end
  end

end
