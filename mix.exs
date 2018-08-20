defmodule Unifex.MixProject do
  use Mix.Project

  def project do
    [
      app: :unifex,
      compilers: [:bundlex] ++ Mix.compilers(),
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:membrane_common_c,
       git: "https://github.com/membraneframework/membrane-common-c.git",
       branch: "feature/shm-payload"},
      {:bundlex, "~> 0.1"}
    ]
  end
end
