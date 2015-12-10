# RedixCluster

**a wrapper for redix to support cluster mode of redis 

## Installation

  1. Add redix_cluster to your list of dependencies in `mix.exs`:
    ```elixir
        def deps do
          [{:redix_cluster, "~> 0.0.1"}]
        end
    ```        

  2. Ensure redix_cluster is started before your application:
     ```elixir
        def application do
          [applications: [:redix_cluster]]
        end
     ```
        
## Help
     ```elixir
       iex -S mix
       iex> h RedixCluster.command
       iex> h RedixCluster.pipeline
       iex> h RedixCluster.transaction
     ```       

## Config
     ```elixir
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
     ```          
          
   `it's never slow down the speed of commands even redis is not on cluster`  

## Test
     ```elixir
        MIX_EVN=test mix espec
     ```
   
## Bench
     ```elixir
       MIX_ENV=bench mix bench
     ```       
       
## Application structure

   ![](http://7fveua.com1.z0.glb.clouddn.com/redix_cluster.jpg)
   
## TODO   

      