defmodule Unifex.MixProject do
  use Mix.Project

  @version "0.2.5"
  @github_link "https://github.com/membraneframework/unifex"

  def project do
    [
      app: :unifex,
      compilers: [:bundlex] ++ Mix.compilers(),
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      name: "Unifex",
      description: "Tool for generating interfaces between native C code and Elixir",
      source_url: @github_link,
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: []
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
      extras: ["README.md", "pages/creating_unifex_nif.md"],
      source_ref: "v#{@version}"
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:bunch, "~> 1.0"},
      {:shmex, "~> 0.2.0"},
      {:bundlex, "~> 0.2.0"}
    ]
  end
end
