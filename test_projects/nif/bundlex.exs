defmodule Example.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      natives: natives(Bundlex.platform())
    ]
  end

  def natives(_platform) do
    language = System.get_env("UNIFEX_TEST_LANG") |> String.to_atom()

    [
      example: [
        src_base: "example",
        sources: ["example.#{language}"],
        preprocessor: Unifex,
        interface: :nif,
        language: language
      ]
    ]
  end
end
