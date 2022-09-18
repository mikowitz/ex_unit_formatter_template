defmodule StringFormatter do
  @moduledoc false

  use ExUnitFormatterTemplate

  def init, do: ""

  def suite_started(_, state) do
    state <> "S["
  end

  def suite_finished(_, state) do
    state <> "]"
  end

  def module_started(%{}, state) do
    state <> "M["
  end

  def module_finished(_, state) do
    state <> "]"
  end

  def test_started(%{}, state) do
    state <> "T["
  end

  def test_finished(_, state) do
    state <> "]"
  end
end
