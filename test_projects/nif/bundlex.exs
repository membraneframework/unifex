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
        src_base: "example",
        sources: ["example.c"],
        preprocessor: Unifex,
        interface: :nif
      ]
    ]
  end
end
