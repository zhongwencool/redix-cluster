defmodule RedixCluster.Transation.Spec do
  use ESpec, shared: true

  before do
    allow Redix |> to accept :start_link, fn(_, _) -> {:ok, self} end, [:non_strict, :unstick]
    allow Redix |> to accept :stop, fn(_) -> :ok end, [:non_strict, :unstick]
    allow Redix |> to accept :command, fn
      (_, ~w(CLUSTER SLOTS), _) -> {:ok,
                                 [[10923, 16383, ["10.1.2.5", 7000], ["10.1.2.5", 7001]],
                                  [5461, 10922, ["10.1.2.6", 7000], ["10.1.2.7", 7001]],
                                  [0, 5460, ["10.1.2.7", 7000], ["10.1.2.6", 7001]]]} end,
    [:non_strict, :unstick]

    allow Redix |> to accept :pipeline, fn
      (_, [["MULTI"], ~w(get {user}a), ~w(get {user}b), ["EXEC"]], _) -> {:ok, ["OK", "QUEUED", "QUEUED", ["usera", "userb"]]}
      (_, [["MULTI"], ~w(set {user}a usera), ~w(set {user}b userb), ["EXEC"]], _) -> {:ok, ["OK", "QUEUED", "QUEUED", ["OK", "OK"]]}
      (_, [~w(set {user}a a), ~w(set {user}b 1), ~w(incr {user}b, b)], _) ->
        {:ok, ["OK", "OK", %Redix.Error{message: "ERR wrong number of arguments for 'incr' command"}]} end,
      [:non_strict, :unstick]

    Application.ensure_all_started(:redix_cluster)
    {:shared, count: 1} #saves {:key, :value} to `shared`
  end

  finally do: {:shared, answer: shared.count + 1}

  context "transation test" do
    it do: expect RedixCluster.transaction([~w(get a ), ~w(get b)]) |> to eq {:error, :key_must_same_slot}
    it do: expect RedixCluster.transaction([~w(set {user}a usera), ~w(set {user}b userb)]) |> to eq {:ok, ["OK", "QUEUED", "QUEUED", ["OK", "OK"]]}
    it do: expect RedixCluster.transaction([~w(get {user}a), ~w(get {user}b)]) |> to eq {:ok, ["OK", "QUEUED", "QUEUED", ["usera", "userb"]]}
  end

  context "transation! test" do
    it do: expect RedixCluster.transaction!([~w(set {user}a usera), ~w(set {user}b userb)]) |> to eq ["OK", "QUEUED", "QUEUED", ["OK", "OK"]]
    it do: expect RedixCluster.transaction!([~w(get {user}a), ~w(get {user}b)]) |> to eq ["OK", "QUEUED", "QUEUED", ["usera", "userb"]]
    it do: expect RedixCluster.pipeline!([~w(set {user}a a), ~w(set {user}b 1), ~w(incr {user}b, b)])
          |> to eq ["OK", "OK", %Redix.Error{message: "ERR wrong number of arguments for 'incr' command"}]
    it do
      action = fn() -> RedixCluster.transaction!([~w(get a ), ~w(get b)]) end
      expect  action |> to raise_exception RedixCluster.Error, "CROSSSLOT Keys in request don't hash to the same slot"
    end
  end

end
