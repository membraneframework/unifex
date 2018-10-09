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
      dirty: 2,
      sends: 1
    ]
  ]
]
