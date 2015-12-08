# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
# copy from redix.ex
#`connection_opts` is a list of options used to manage the connection. These
#  are the Redix-specific options that can be used:

#    * `:socket_opts` - (list of options) this option specifies a list of options
#      that are passed to `:gen_tcp.connect/4` when connecting to the Redis
#      server. Some socket options (like `:active` or `:binary`) will be
#      overridden by Redix so that it functions properly. Defaults to `[]`.
#    * `:backoff` - (integer) the time (in milliseconds) to wait before trying to
#      reconnect when a network error occurs. Defaults to `2000`.
#    * `:max_reconnection_attempts` - (integer or `nil`) the maximum number of
#      reconnection attempts that the Redix process is allowed to make. When the
#      Redix process "consumes" all the reconnection attempts allowed to it, it
#      will exit with the original error's reason. If the value is `nil`, there's
#      no limit to the reconnection attempts that can be made. Defaults to `nil`.

#     config :exredis_cluster, key: :value
config :exredis_cluster,
  cluster_nodes: [%{host: '10.1.2.7', port: 7000},
                  %{host: '10.1.2.6', port: 7000},
                  %{host: '10.1.2.5', port: 7000}
                 ],
  pool_size: 5,
  pool_max_overflow: 0,

# connection_opts
  socket_opts: [],
  backoff: 2000,
  max_reconnection_attempts: nil

#
# And access this configuration in your application as:
#
#     Application.get_env(:exredis_cluster, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
 import_config "#{Mix.env}.exs"
