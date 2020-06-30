defmodule Unifex.BundlexProject do
  use Bundlex.Project

  def project do
    [
      libs: libs()
    ]
  end

  defp libs do
    [
      unifex_nif: [
        deps: [shmex: :lib_nif],
        src_base: "unifex/nif/unifex",
        sources: ["unifex.c", "payload.c"]
      ],
      unifex_cnode: [
        src_base: "unifex/cnode/unifex",
        sources: ["unifex_cnode.c"]
      ]
    ]
  end
end
