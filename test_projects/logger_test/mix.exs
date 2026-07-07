defmodule LoggerTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :logger_test,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      compilers: [:unifex, :bundlex] ++ Mix.compilers(),
      bundlex: [natives: natives()]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      env: [unifex: [enable_logger: true]]
    ]
  end

  defp natives do
    [
      logger_test: [
        sources: ["logger_test.c"],
        interface: [:nif, :cnode],
        preprocessor: Unifex
      ]
    ]
  end

  defp deps do
    [
      {:unifex, path: "../../"},
      {:bundlex, "~> 1.0"}
    ]
  end

  defp aliases do
    [
      "compile.with.warnings": ["compile", "--warnings-as-errors"],
      "test.all": ["test", "--warnings-as-errors"]
    ]
  end
end