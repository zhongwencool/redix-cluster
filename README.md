# RedixCluster

**a wrapper for redix to support cluster mode of redis 3.0.0+

## Installation

  1. Add redix_cluster to your list of dependencies in `mix.exs`:

        def deps do
          [{:redix_cluster, "~> 0.0.1"}]
        end

  2. Ensure redix_cluster is started before your application:

        def application do
          [applications: [:redix_cluster]]
        end
        
## Help
       iex -S mix
       iex> h RedixCluster.command
       iex> h RedixCluster.pipeline
       iex> h RedixCluster.transaction

## Config
        config :redix_cluster,
          cluster_nodes: [%{host: '10.1.2.7', port: 7000},
                          %{host: '10.1.2.6', port: 7000},
                          %{host: '10.1.2.5', port: 7000}
                         ],
        # poolboy                         
          pool_size: 5,
          pool_max_overflow: 0,
        
        # redix connection_opts
          socket_opts: [],
          backoff: 2000,
          max_reconnection_attempts: nil
          
   if your use this project when  redis is not cluster, just config
   
         cluster_nodes: [%{host: '10.1.2.7', port: 7000}]
   it will establish several connections between poolboy pools(pool_size) and redis

## Test  
        MIX_EVN=test mix espec
   
## Bench

       MIX_ENV=bench mix bench
       
##Application‘s structure

   ![](http://7fveua.com1.z0.glb.clouddn.com/redix_cluster.jpg)
   
##TODO   

      