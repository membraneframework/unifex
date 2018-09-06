[
  inputs: [
    "{lib,test,config}/**/*.{ex,exs}",
    "*.exs"
  ],
  import_deps: [:bundlex],
  export: [
    locals_without_parens: [
      module: 1,
      spec: 1,
      sends: 1
    ]
  ]
]
