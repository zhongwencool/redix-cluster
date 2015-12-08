defmodule RedisCluster.Helper do
  @moduledoc false

  defmacro __using__(_opts) do
    quote  do
      def get_env(key, default \\ nil) do
        Application.get_env(:exredis_cluster, key, default)
      end
    end
  end
  
end