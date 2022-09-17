defmodule JsonFormatter do
  use ExUnitFormatterTemplate

  def suite_finished(_, state) do
    Jason.encode!(state)
  end
end
