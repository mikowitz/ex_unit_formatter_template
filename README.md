# ExUnitFormatterTemplate

`ExUnitFormatterTemplate` provides a simplified wrapper around the `GenServer`
code necessary to create a custom `ExUnit` formatter.

This library aims to abstract away some of the repetition inherent in creating
a `GenServer` by providing a simple API to hook into the events sent by the test
runner.

## Usage

To begin, create a new module for your formatter, and `use` the
`ExUnitFormatterTemplate`

```elixir
defmodule YourFormatter do
  use ExUnitFormatterTemplate
end
```

### Default formatter

Without adding any code to the above example, you already have a working, albeit
basic, test formatter. `ExUnitFormatterTemplate` provides a default implementation
that records the total number of tests run, as well as the counts for each
completion result, and prints out the resulting map when the suite has finished running.

It's not exciting, but it ensures that you have useful test suite data to get started
as you develop your formatter.

### `ExUnitFormatterTemplate` behaviour

`use`-ing `ExUnitFormatterTemplate` sets your module up to implement the
`ExUnitFormatterTemplate` behaviour, which provides the following
(all optional) callbacks:

* `init/0`
* `suite_started/2`
* `suite_finished/2`
* `module_started/2`
* `module_finished/2`
* `test_started/2`
* `test_finished/2`

The names of the callbacks should give you a good idea of where they are invoked
during the test run. See the `ExUnitFormatterTemplate` documentation for complete
explanations.

With the exception of `init/0`, each of these callbacks takes as its first argument
the metadata related to the part of the test suite (the suite itself, a module,
or an individual test), and as its second argument the built up state of the test suite.
Each callback is expected to return this state as a single return value.

`init/0` takes no arguments, and is expected to return a new state to be passed
through the other callbacks. This can take whatever form you want.

Because all of these callbacks are optional, you are able to only define those for
which you wish to take a specific action. Otherwise, with the exception of
`init/0` and `test_finished/2`, which have default implementations in `ExUnitFormatterTemplate`,
all unimplemented callbacks are simple pass-throughs. `suite_finished/2` also has a default
implementation, but it is simply

```elixir
def suite_finished(_suite_data, state), do: IO.inspect(state)
```

so it can safely be left unimplemented without concern for any custom state shape
you may be using in your formatter

### Running tests with your formatter

To run tests with your formatter, pass the name of your formatter module to `mix test`
using the `--formatter` flag:

```sh
mix test --formatter YourFormatter
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_unit_formatter_template` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_unit_formatter_template, "~> 0.0.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_unit_formatter_template>.

