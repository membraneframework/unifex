# Unifex

[![Hex.pm](https://img.shields.io/hexpm/v/unifex.svg)](https://hex.pm/packages/unifex)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/unifex/)
[![Build Status](https://travis-ci.com/membraneframework/unifex.svg?branch=master)](https://travis-ci.com/membraneframework/unifex)

Unifex is a tool for generating interfaces between native C code and Elixir, that:
- provides intuitive and conscise tools for defining native interfaces,
- generates all the boilerplate for you,
- provides useful abstractions over binaries and state,
- makes native code independent from `erl_nif` library, so once port-based interface is supported, the same code will be usable either with NIFs or ports.

API documentation is available at [HexDocs](https://hexdocs.pm/unifex/).

## Instalation

To install, you need to configure Mix project as follows:

```elixir
defmodule MyApp.Mixfile do
  use Mix.Project

  def project do
    [
      app: :my_app,
      compilers: [:unifex, :bundlex] ++ Mix.compilers, # add unifex and bundlex to compilers
      ...,
      deps: deps()
   ]
  end

  defp deps() do
    [
      {:unifex, "~> 0.2.0"} # add unifex to deps
    ]
  end
end
```

## Usage

  For detailed usage description see [Creating Unifex NIF](https://hexdocs.pm/unifex/creating_unifex_nif.html) guide.

## See also

  Unifex depends on the following libraries:
  - [Bundlex](https://github.com/membraneframework/bundlex)
  - [Shmex](https://github.com/membraneframework/shmex)

## Copyright and License

Copyright 2018, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://membraneframework.github.io/static/logo/swm_logo_readme.png)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)
