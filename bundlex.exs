defmodule Unifex.BundlexProject do
  use Bundlex.Project

  def project do
    [
      nifs: nifs(Bundlex.platform())
    ]
  end

  defp nifs(platform) do
    [
      unifex: [
        deps: [membrane_common_c: :membrane_shm_payload_lib],
        libs:
          case platform do
            :linux -> ["uuid"]
            _ -> []
          end,
        export_only?: Mix.env() != :test,
        sources: ["unifex.c"]
      ]
    ]
  end
end
