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
        src_base: "example",
        sources: ["example.c"],
        preprocessor: Unifex
      ]
    ]
  end
end
