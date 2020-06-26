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
        deps: [unifex: :unifex_cnode],
        src_base: "example",
        sources: ["_generated/example.c", "example.c"]
      ]
    ]
  end
end
