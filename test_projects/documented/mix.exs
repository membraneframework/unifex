defmodule Unified.MixProject do
  use Mix.Project

  def project do
    [
      app: :unified,
      version: "0.1.0",
      elixir: "~> 1.10",
      compilers: [:unifex, :bundlex] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:unifex, path: "../.."},
      {:elixir_sense, github: "elixir-lsp/elixir_sense", only: :test}
    ]
  end
end
