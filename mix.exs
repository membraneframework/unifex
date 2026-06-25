defmodule Unifex.MixProject do
  use Mix.Project

  @version "1.2.4"
  @github_url "https://github.com/membraneframework/unifex"

  def project do
    [
      app: :unifex,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      compilers: [:bundlex] ++ Mix.compilers(),
      deps: deps(),
      dialyzer: dialyzer(),

      # hex
      description: "Tool for generating interfaces between native C code and Elixir",
      package: package(),

      # docs
      name: "Unifex",
      source_url: @github_url,
      homepage_url: "https://membraneframework.org",
      docs: docs(),
      aliases: [docs: ["docs", &prepend_llms_links/1]]
    ]
  end

  def application do
    [
      extra_applications: [],
      mod: {Unifex.App, []}
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache-2.0"],
      files: ["lib", "c_src", "mix.exs", "README*", "LICENSE*", ".formatter.exs", "bundlex.exs"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "LICENSE",
        "pages/creating_unifex_natives.md",
        "pages/creating_unifex_nif.md",
        "pages/supported_types.md"
      ],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [
        Unifex.CodeGenerators,
        Unifex.CodeGenerator.BaseTypes
      ],
      groups_for_modules: [
        CodeGenerators: [~r/Unifex\.CodeGenerators\.*/],
        BaseTypes: [~r/Unifex\.CodeGenerator.BaseTypes\.*/]
      ]
    ]
  end

  defp dialyzer() do
    opts = [
      flags: [:error_handling],
      plt_add_apps: [:mix]
    ]

    if System.get_env("CI") == "true" do
      # Store PLTs in cacheable directory for CI
      [plt_local_path: "priv/plts", plt_core_path: "priv/plts"] ++ opts
    else
      opts
    end
  end

  defp deps do
    [
      {:bunch, "~> 1.0"},
      {:shmex, "~> 0.5.0"},
      {:bundlex, "~> 1.4"},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:credo, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp prepend_llms_links(_) do
    output_dir = docs()[:output] || "doc"
    path = Path.join(output_dir, "llms.txt")

    if File.exists?(path) do
      existing = File.read!(path)

      footer = """


      ## See Also

      - [Membrane Framework AI Skill](https://hexdocs.pm/membrane_core/skill.md)
      - [Membrane Core](https://hexdocs.pm/membrane_core/llms.txt)
      """

      File.write!(path, String.trim_trailing(existing) <> footer)
    else
      IO.warn("#{path} not found — llms.txt was not generated, check your ex_doc configuration")
    end
  end
end
