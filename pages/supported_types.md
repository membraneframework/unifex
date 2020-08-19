# Supported types

Unifenosupports generating code both for usage with NIF's and CNode's. 
Nevertheless, some types can be not implemented yet.
Below we present which types you can use at this moment. 
You can also refer to [#42](https://github.com/membraneframework/unifenoissues/42) to see 
state of work on remaining types.

## NIF
| type    | as function parameter | as return type  |
| ------- | :-------------------: | :-------------: |
| atom    | yes                   | yes             |
| bool    | yes                   | yes             |
| uint    | yes                   | yes             |
| uint64  | yes                   | yes             |
| int     | yes                   | yes             |
| int64   | yes                   | yes             |
| list    | yes                   | yes             |
| payload | yes                   | yes             |
| pid     | yes                   | yes             |
| string  | yes                   | yes             |

## CNode
| type    | as function parameter | as return type  |
| ------- | :-------------------: | :-------------: |
| atom    | yes                   | yes             |
| bool    | no                    | no              |
| uint    | yes                   | yes             |
| uint64  | no                    | no              |
| int     | yes                   | yes             |
| int64   | no                    | no              |
| list    | yes                   | yes             |
| payload | yes                   | yes             |
| pid     | yes                   | yes             |
| string  | yes                   | yes             |
