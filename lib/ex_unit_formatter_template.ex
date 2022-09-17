defmodule ExUnitFormatterTemplate do
  # TODO: better typespecs for the callbacks
  @callback suite_started(term, term) :: term
  @callback suite_finished(term, term) :: term
  @callback case_started(term, term) :: term
  @callback case_finished(term, term) :: term

  @callback test_started(term, term) :: term
  @callback test_finished(term, term) :: term
  @callback module_started(term, term) :: term
  @callback module_finished(term, term) :: term

  @callback init :: term

  @optional_callbacks suite_started: 2,
                      suite_finished: 2,
                      case_started: 2,
                      case_finished: 2,
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

      @supported_cast_events ~w(
        suite_started suite_finished
        case_started case_finished
        test_started test_finished
        module_started module_finished
      )a

      def init(_) do
        state = run_if_defined?({:init, 0}, [])

        {:ok, state}
      end

      def handle_cast({event, event_data}, state) when event in @supported_cast_events do
        run_if_defined?({event, 2}, [event_data, state])
        |> noreply(state)
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
  def suite_finished(_suite_data, state), do: state

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
