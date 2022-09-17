defmodule ExUnitFormatterTemplateTest do
  use ExUnit.Case

  alias SampleFormatter, as: SF

  describe "default formatter" do
    test "does the right thing" do
      {:ok, formatter} = GenServer.start_link(SF, [nil])

      GenServer.cast(formatter, {:suite_started, %{}})

      log_passing_test(formatter)
      log_failing_test(formatter)

      GenServer.cast(formatter, {:suite_finished, %{}})

      state = :sys.get_state(formatter)

      GenServer.stop(formatter)

      assert state.total == 2
      assert state.passed == 1
      assert state.failed == 1
    end
  end

  defp log_passing_test(formatter) do
    GenServer.cast(formatter, {:test_finished, %{state: nil}})
  end

  defp log_failing_test(formatter) do
    GenServer.cast(formatter, {:test_finished, %{state: {:failed, %{}}}})
  end
end
