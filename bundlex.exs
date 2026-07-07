defmodule Unifex.BundlexProject do
  use Bundlex.Project

  def project do
    [
      libs: libs()
    ]
  end

  defp libs do
    [
      unifex: [
        deps: [shmex: :shmex],
        src_base: "unifex/nif/unifex",
        sources: ["unifex.c", "payload.c", "../../unifex/logger.c", "../../unifex/logger_nif.c"],
        # Lets consumers `#include <unifex/logger.h>` regardless of where the
        # unifex dependency is fetched from - logger.h/logger_backend.h live
        # outside both the nif/ and cnode/ source trees, shared by both.
        includes: [Path.join(__DIR__, "c_src/unifex")],
        libs: ["pthread"],
        interface: :nif
      ],
      unifex: [
        src_base: "unifex/cnode/unifex",
        sources: ["unifex.c", "cnode.c", "payload.c", "../../unifex/logger.c", "../../unifex/logger_cnode.c"],
        includes: [Path.join(__DIR__, "c_src/unifex")],
        libs: ["pthread"],
        interface: :cnode
      ]
    ]
  end
end
