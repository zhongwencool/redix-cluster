defmodule RedixCluster.Mixfile do
  use Mix.Project

  def project do
    [app: :redix_cluster,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env in [:prod],
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {RedixCluster, []},
    applications: [:logger, :redix]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [ {:redix, "~> 0.3.0"},
      {:poolboy, "~> 1.5", override: true},
      {:dialyze, "~> 0.2", only: :dev},
      {:benchfella, github: "alco/benchfella", only: :dev},
      {:eredis_cluster, github: "adrienmo/eredis_cluster", only: :dev},
    ]
  end
end
