defmodule ExUnitFormatterTemplate do
  @moduledoc """
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

  """

  @typedoc """
    The shape of the state your formatter builds up over the test suite run.
    This can be any valid Elixir data shape.

    If you do not implement this callback, the default state is a map with keys
    for each possible test outcome and integers for values.
  """
  @type state :: term()

  @doc """
    Called when the test suite begins.

    The first argument is the set of options you have configured for the test run
    via command line flags or in `test_helper.exs`, and the second argument is your
    formatter's state.
  """
  @callback suite_started(suite_options :: Keyword.t(), state()) :: state()

  @doc """
    Called when the test suite completes.

    The first argument is a map of timing data for the test suite (times given
    in milliseconds), and the second argument is your formatter's state.

    See `t:ExUnit.Formatter.times_us/0` for additional information about this data.
  """
  @callback suite_finished(suite_data :: ExUnit.Formatter.times_us(), state()) :: state()

  @doc """
    Called when an individual test begins.

    The first argument is an `ExUnit.Test` struct containing data about the test
    being run, and the second argument is your formatter's state.

    See `t:ExUnit.Test.t/0` for additional information about this data.
  """
  @callback test_started(test_data :: ExUnit.Test.t(), state()) :: state()

  @doc """
    Called when an individual test completes.

    The first argument is an `ExUnit.Test` struct containing data about the test
    being run, and the second argument is your formatter's state.

    See `t:ExUnit.Test.t/0` for additional information about this data.
  """
  @callback test_finished(test_data :: ExUnit.Test.t(), state()) :: state()

  @doc """
    Called when the tests contained in a single module begin running.

    The first argument is an `ExUnit.TestModule` struct that contains data
    about the module whose tests are being run, and the second argument
    is your formatter's state.

    See `t:ExUnit.TestModule.t/0` for additional information about this data.
  """
  @callback module_started(module_data :: ExUnit.TestModule.t(), state()) :: state()

  @doc """
    Called when the tests contained in a single module finish running.

    The first argument is an `ExUnit.TestModule` struct that contains data
    about the module whose tests have just been run, and the second argument
    is your formatter's state.

    See `t:ExUnit.TestModule.t/0` for additional information about this data.
  """
  @callback module_finished(module_data :: ExUnit.TestModule.t(), state()) :: state()

  @doc """
    Called before the test suite is run. This callback allows you to define the
    data shape of the state your formatter builds up over the course of the
    test suite run.
  """
  @callback init :: state()

  @optional_callbacks suite_started: 2,
                      suite_finished: 2,
                      test_started: 2,
                      test_finished: 2,
                      module_started: 2,
                      module_finished: 2,
                      init: 0

  defmacro __using__(_) do
    quote do
      use GenServer
      require Logger

      @behaviour unquote(__MODULE__)

      @supported_events ~w(
        suite_started suite_finished
        test_started test_finished
        module_started module_finished
      )a

      @deprecated_events ~w(case_started case_finished)a

      def init(_) do
        state = run_if_defined?({:init, 0}, [])

        {:ok, state}
      end

      def handle_cast({event, event_data}, state) when event in @supported_events do
        run_if_defined?({event, 2}, [event_data, state])
        |> noreply(state)
      end

      # According to the ExUnit docs, these events are still called,
      # but are deprecated and can be ignored. Thus, we want to exclude
      # them from our callbacks, but also not pollute output with logs
      # related to them, as below.
      def handle_cast({event, _}, state) when event in @deprecated_events do
        {:noreply, state}
      end

      def handle_cast({event, _data}, state) do
        Logger.info("Received unexpected event: #{event}")
        {:noreply, state}
      end

      defp noreply(nil, state), do: {:noreply, state}
      defp noreply(new_state, _), do: {:noreply, new_state}

      defp run_if_defined?({func, parity}, args) do
        module =
          case Kernel.function_exported?(__MODULE__, func, parity) do
            true -> __MODULE__
            false -> unquote(__MODULE__)
          end

        apply(module, func, args)
      end
    end
  end

  @doc false
  def init, do: %{total: 0, passed: 0, failed: 0, skipped: 0, excluded: 0, invalid: 0}

  @doc false
  def suite_started(_suite_data, state), do: state

  @doc false
  def suite_finished(_suite_data, state), do: IO.inspect(state)

  @doc false
  def case_started(_case_state, state), do: state

  @doc false
  def case_finished(_case_state, state), do: state

  @doc false
  def module_started(_module_state, state), do: state

  @doc false
  def module_finished(_module_state, state), do: state

  @doc false
  def test_started(_test_state, state), do: state

  @doc false
  def test_finished(test_state, state) do
    result = get_test_outcome(test_state)

    state
    |> Map.update(result, 0, &inc/1)
    |> Map.update(:total, 0, &inc/1)
  end

  defp get_test_outcome(%{state: nil}), do: :passed
  defp get_test_outcome(%{state: {result, _}}), do: result

  defp inc(n), do: n + 1
end
