# RedixCluster

**TODO: Add description**

## Installation

  1. Add redix_cluster to your list of dependencies in `mix.exs`:

        def deps do
          [{:redix_cluster, "~> 0.0.1"}]
        end

  2. Ensure redix_cluster is started before your application:

        def application do
          [applications: [:redix_cluster]]
        end
