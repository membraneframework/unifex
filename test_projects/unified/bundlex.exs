defmodule Example.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      natives: natives(Bundlex.platform())
    ]
  end

  def natives(_platform) do
    [
      example: [
        deps: [unifex: :unifex],
        src_base: "example",
        sources: ["_generated/nif/example.c", "example.c"],
        interface: :nif
      ],
      example: [
        deps: [unifex: :unifex],
        src_base: "example",
        sources: ["_generated/cnode/example.c", "example.c"],
        interface: :cnode
      ]
    ]
  end
end
