defmodule Example.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      nifs: nifs(Bundlex.platform())
    ]
  end

  def nifs(_platform) do
    [
      example: [
        src_base: "example",
        sources: ["example.c"],
        preprocessor: Unifex
      ]
    ]
  end
end
