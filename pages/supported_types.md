# Supported types

Unifex supports generating code both for usage with NIF's and CNode's. 
Nevertheless, some types can be not implemented yet.
Below we present which types you can use at this moment. 
You can also refer to [#42](https://github.com/membraneframework/unifex/issues/42) to see 
state of work on remaining types.

## NIF
| type      | as function parameter | as return type  |
| --------- | :-------------------: | :-------------: |
| `atom`    | yes                   | yes             |
| `bool`    | yes                   | yes             |
| `unsigned`| yes                   | yes             |
| `uint64`  | yes                   | yes             |
| `int`     | yes                   | yes             |
| `int64`   | yes                   | yes             |
| `float`   | yes                   | yes             |
| `list`    | yes                   | yes             |
| `payload` | yes                   | yes             |
| `pid`     | yes                   | yes             |
| `string`  | yes                   | yes             |

## CNode
| type      | as function parameter | as return type  |
| --------- | :-------------------: | :-------------: |
| `atom`    | yes                   | yes             |
| `bool`    | yes                   | yes             |
| `unsigned`| yes                   | yes             |
| `uint64`  | no                    | no              |
| `int`     | yes                   | yes             |
| `int64`   | no                    | no              |
| `float`   | yes                   | yes             |
| `list`    | yes                   | yes             |
| `payload` | yes                   | yes             |
| `pid`     | yes                   | yes             |
| `string`  | yes                   | yes             |

## Types mapping
List of examples, how specific type in `*.spec.exs` will be translated onto native side

Elixir type | Native type
--- | ---
`atom` | `char *`
`bool` | `int`
`float` | `double`
`int` | `int`
`int64` | `int64_t`
`payload` | `UnifexPayload`
`pid` | `UnifexPid`
`state` | `UnifexState *`
`string` | `char *`
`uint64` | `uint64_t`
`unsigned` | `unsigned int`
`[int]` | `int *`, `unsigned int`