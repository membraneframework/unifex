defmodule Example.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      cnodes: cnodes(Bundlex.platform())
    ]
  end

  def cnodes(_platform) do
    [
      example: [
        deps: [unifex: :unifex],
        src_base: "example",
        sources: ["_generated/cnode/example.c", "example.c"]
      ]
    ]
  end
end
