defmodule ExUnitFormatterTemplate do
  @type state :: term()

  @callback suite_started(Keyword.t(), state()) :: state()
  @callback suite_finished(ExUnit.Formatter.times_us(), state()) :: state()
  @callback test_started(ExUnit.Test.t(), state()) :: state()
  @callback test_finished(ExUnit.Test.t(), state()) :: state()
  @callback module_started(ExUnit.TestModule.t(), state()) :: state()
  @callback module_finished(ExUnit.TestModule.t(), state()) :: state()

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

  def init, do: %{total: 0, passed: 0, failed: 0, skipped: 0, excluded: 0, invalid: 0}
  def final(_reason, state), do: state

  def suite_started(_suite_data, state), do: state
  def suite_finished(_suite_data, state), do: IO.inspect(state)

  def case_started(_case_state, state), do: state
  def case_finished(_case_state, state), do: state

  def module_started(_module_state, state), do: state
  def module_finished(_module_state, state), do: state

  def test_started(_test_state, state), do: state

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
