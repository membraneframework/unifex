defmodule Unifex.MixProject do
  use Mix.Project

  @version "0.1.0"
  @github_link "https://github.com/membraneframework/unifex"

  def project do
    [
      app: :unifex,
      compilers: [:bundlex] ++ Mix.compilers(),
      version: @version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      name: "Unifex",
      description: "An abstraction over native code",
      source_url: @github_link,
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      files: ["lib", "c_src", "mix.exs", "README*", "LICENSE*", ".formatter.exs", "bundlex.exs"],
      links: %{
        "GitHub" => @github_link,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}"
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:bunch, "~> 0.1"},
      {:shmex, "~> 0.1"},
      {:bundlex, "~> 0.1"}
    ]
  end
end
