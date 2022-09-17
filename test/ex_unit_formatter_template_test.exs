defmodule ExUnitFormatterTemplateTest do
  use ExUnit.Case

  describe "default formatter" do
    test "provides a sensible default behaviour to log result counts" do
      {:ok, formatter} = GenServer.start_link(SampleFormatter, [nil])

      cast(formatter, :suite_started)

      cast(formatter, :test_finished, %{state: nil})
      cast(formatter, :test_finished, %{state: {:failed, %{}}})
      cast(formatter, :test_finished, %{state: {:skipped, %{}}})

      cast(formatter, :suite_finished)

      state = :sys.get_state(formatter)

      GenServer.stop(formatter)

      assert state.total == 3
      assert state.passed == 1
      assert state.failed == 1
      assert state.skipped == 1
    end
  end

  describe "custom formatter" do
    test "overrides the default behaivour" do
      {:ok, formatter} = GenServer.start_link(StringFormatter, [nil])

      cast(formatter, :suite_started)

      cast(formatter, :case_started)

      cast(formatter, :module_started)

      cast(formatter, :test_started)
      cast(formatter, :test_finished)

      cast(formatter, :test_started)
      cast(formatter, :test_finished)

      cast(formatter, :module_finished)

      cast(formatter, :case_finished)

      cast(formatter, :suite_finished)

      state = :sys.get_state(formatter)

      GenServer.stop(formatter)

      assert state == "S[C[M[T[]T[]]]]"
    end
  end

  describe "partial formatter" do
    test "doesn't have to override every callback" do
      {:ok, formatter} = GenServer.start_link(JsonFormatter, [nil])

      cast(formatter, :suite_started)

      cast(formatter, :test_finished, %{state: nil})
      cast(formatter, :test_finished, %{state: {:failed, %{}}})

      cast(formatter, :suite_finished)

      state = :sys.get_state(formatter)

      GenServer.stop(formatter)

      state = Jason.decode!(state, keys: :atoms)

      assert state.total == 2
      assert state.passed == 1
      assert state.failed == 1
    end
  end

  defp cast(formatter, event, data \\ %{}) do
    GenServer.cast(formatter, {event, data})
  end
end
