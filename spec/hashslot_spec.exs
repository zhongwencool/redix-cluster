defmodule CreateHashSlot.Spec do

  use ESpec

  @chars ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p",
          "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]

  it  do
    chars_hash |> to eq [15495, 3300, 7365, 11298, 15363, 3168, 7233, 11694, 15759, 3564, 7629, 11562,
                         15627, 3432, 7497, 16023, 11958, 7893, 3828, 15891, 11826, 7761, 3696, 16287,
                         12222, 8157]
  end

  it do
    same_hash |> to eq List.duplicate(15495, 100)
  end

  defp chars_hash() do
    for char <- @chars, do: RedixCluster.Hash.hash(char)
  end

  defp same_hash() do
    for char <- List.duplicate("{a}", 100), do: RedixCluster.Run.key_to_slot_hash("#{char}+#{:random.uniform}")
  end

 end
