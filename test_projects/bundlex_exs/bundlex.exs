defmodule BundlexExs.BundlexProject do
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
        sources: ["example.c"],
        interface: [:nif, :cnode],
        preprocessor: Unifex
      ],
    ]
  end
end
