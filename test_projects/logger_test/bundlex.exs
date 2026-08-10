defmodule LoggerTest.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      natives: natives(Bundlex.get_target())
    ]
  end

  defp natives(_platform) do
    [
      logger_test: [
        sources: ["logger_test.c"],
        interface: [:nif, :cnode],
        preprocessor: Unifex
      ]
    ]
  end
end