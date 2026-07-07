# Logging from native code

Unifex ships a non-blocking logger that lets native code (NIFs and CNodes alike) send
log messages to the BEAM without blocking the calling thread. Messages are queued in C,
drained by a dedicated worker thread, and forwarded to Elixir's `Logger`.

The same `unifex_log()` call works whether your native is compiled as a NIF or a CNode -
you don't need to know or care which backend is active.

## Enabling it

The logger's `GenServer` (`Unifex.Logger`) is not started by default, so that projects
which never call `unifex_log()` don't pay for an idle process and a native worker thread.
Enable it in your app's `config/config.exs`:

```elixir
import Config

config :unifex, enable_logger: true
```

Note that this must be set via `config/config.exs` (or `runtime.exs`), not via the
`:env` key of your own app in `mix.exs` - the latter only sets your own application's
environment, not `:unifex`'s.

## Calling it from C

No extra `bundlex.exs` configuration is needed beyond what any Unifex native already
requires (`preprocessor: Unifex`) - the logger's C sources and the `<unifex/logger.h>`
include path are wired in automatically for every native that depends on Unifex.

```c
#include <unifex/logger.h>

UNIFEX_TERM process(UnifexEnv *env, int num) {
  const char *tags[] = {"my_native", "processing"};

  bool queued = unifex_log(UNIFEX_LOG_LEVEL_INFO, "Processing started", tags, 2);
  if (!queued) {
    // The queue was full and the message was dropped - logging is
    // best-effort and never blocks or fails the caller.
  }

  // ...

  return process_result_ok(env, num);
}
```

### `unifex_log`

```c
bool unifex_log(const char *level, const char *message, const char **tags,
                unsigned int tags_length);
```

* `level` - one of the `UNIFEX_LOG_LEVEL_DEBUG` / `_INFO` / `_WARN` / `_ERROR` constants
  (or any other string; it's copied, so any level your `Unifex.Logger` handler
  understands works).
* `message` - the log message. Must not be `NULL`.
* `tags` / `tags_length` - an optional array of extra tag strings attached to the
  message (pass `NULL, 0` for none).
* Returns `false` if the message was dropped (queue full, or `message` was `NULL`) -
  logging is always non-blocking and never raises or crashes the caller.

## Where the messages go

Once enabled, `Unifex.Logger` receives every queued message and forwards it to Elixir's
`Logger`, so it goes through your app's normal log level filtering, backends, and
formatting. Its own log line looks like:

```
[2026-07-07T10:45:11.254698Z] [my_native] [processing] Processing started
```

with `Logger` metadata attached:

```elixir
[tags: ["my_native", "processing"], unifex_nif: true, timestamp: 1_772_995_511_254_698]
```

`timestamp` is microseconds since the Unix epoch, taken at the moment `unifex_log()`
was called (not when the message was eventually delivered).

## Behavior notes

* The queue holds up to 256 pending messages. If it fills up (the worker thread can't
  keep up with logging volume), further calls to `unifex_log()` return `false` and the
  message is dropped; once the queue drains, a single `warning`-level message reports how
  many were dropped.
* Delivery is best-effort: `unifex_log()` never blocks the calling thread waiting for the
  message to be sent.
* You don't need to call any logger-specific init/cleanup function yourself - both the
  NIF and CNode backends wire themselves up automatically as part of the normal Unifex
  native lifecycle.
