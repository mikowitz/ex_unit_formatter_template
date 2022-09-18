defmodule JsonFormatter do
  @moduledoc false

  use ExUnitFormatterTemplate

  def suite_finished(_, state) do
    Jason.encode!(state)
  end
end
