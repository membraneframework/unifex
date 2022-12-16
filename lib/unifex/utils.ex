defmodule Unifex.Utils do
  @moduledoc false

  @spec clang_format_installed?() :: boolean()
  def clang_format_installed?() do
    if System.find_executable("clang-format"), do: true, else: false
  end
end
