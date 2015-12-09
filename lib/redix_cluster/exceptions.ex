defmodule RedixCluster.Error do
  @moduledoc """
  Error returned by RedisCluster.
  """
  defexception [:message]

  def exception(reason) when is_binary(reason), do: %__MODULE__{message: reason}

  def exception(:no_connection), do: %__MODULE__{message: "can't connection with redis"}

  def exception(:invalid_cluster_command), do: %__MODULE__{message: "invalid_cluster_command"}

  def exception(:key_must_same_slot), do: %__MODULE__{message: "CROSSSLOT Keys in request don't hash to the same slot"}

  def exception(:no_support_transaction), do: %__MODULE__{message: "cluster pipeline don't support MULTI, using transation"}

  def exception(other)when is_atom(other), do: %Redix.ConnectionError{message: :inet.format_error(other)}

  @type t :: %__MODULE__{message: binary} | %Redix.ConnectionError{message: binary}

end
