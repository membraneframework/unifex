# Supported types

Unifex supports generating code both for usage with NIF's and CNode's. 
Nevertheless, some types can be not implemented yet.
Below we present which types you can use at this moment. 
You can also refer to [#42](https://github.com/membraneframework/unifex/issues/42) to see 
state of work on remaining types.

## Supported types
| Elixir type | Native type                     | in NIF as a function parameter | in NIF as a return type | in CNode as a function parameter | in CNode as a return type  |
| ---------   | :-----------------------------: | :-------------------------: | :------------------: | :---------------------------: | :---------------------: |
| `atom`      | `char *`                        | ✅                          | ✅                    | ✅                            | ✅                      |
| `bool`      | `int`                           | ✅                          | ✅                    | ✅                            | ✅                      |
| `unsigned`  | `unsigned int`                  | ✅                          | ✅                    | ✅                            | ✅                      |
| `uint64`    | `uint64_t`                      | ✅                          | ✅                    | ❌                            | ❌                      |
| `int`       | `int`                           | ✅                          | ✅                    | ✅                            | ✅                      |
| `int64`     | `int64_t`                       | ✅                          | ✅                    | ❌                            | ❌                      |
| `float`     | `double`                        | ✅                          | ✅                    | ✅                            | ✅                      |
| `payload`   | `UnifexPayload`                 | ✅                          | ✅                    | ✅                            | ✅                      |
| `pid`       | `UnifexPid`                     | ✅                          | ✅                    | ✅                            | ✅                      |
| `string`    | `char *`                        | ✅                          | ✅                    | ✅                            | ✅                      |
| `[type]`    | `native_type *`, `unsigned int` | ✅                          | ✅                    | ✅                            | ✅                      |
