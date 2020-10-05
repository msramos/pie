defmodule PieTest do
  use ExUnit.Case
  doctest Pie

  alias Pie.State

  @sut Pie

  test "a succesful pipeline returns an ok tuple" do
    result =
      10
      |> @sut.pipeline()
      |> add(10)
      |> add(2)
      |> divide(2)
      |> @sut.finish()

    assert result == {:ok, 11}
  end

  test "a failed pipeline returns an error tuple with the latest state" do
    result =
      10
      |> @sut.pipeline()
      |> add(10)
      |> divide(0)
      |> @sut.finish()

    assert result ==
             {:error,
              %State{
                error: "division by zero",
                current_value: 20,
                initial_value: 10,
                update_count: 1,
                valid?: false
              }}
  end

  test "track_update: true will keep a record of all updates for a failed pipeline" do
    result =
      10
      |> @sut.pipeline(track_updates: true)
      |> add(15, "adding 15")
      |> add(2)
      |> divide(0)
      |> @sut.finish()

    assert result ==
             {:error,
              %State{
                error: "division by zero",
                updates: [
                  {25, 27},
                  {"adding 15", 10, 25}
                ],
                current_value: 27,
                initial_value: 10,
                update_count: 2,
                valid?: false,
                track_updates?: true
              }}
  end

  defp add(state = %State{current_value: current}, value) do
    State.update(state, current + value)
  end

  defp add(state = %State{current_value: current}, value, label) do
    State.update(state, current + value, label: label)
  end

  defp divide(state = %State{}, 0) do
    State.invalidate(state, "division by zero")
  end

  defp divide(state = %State{current_value: current}, value) do
    State.update(state, current / value)
  end

  defp divide(state = %State{}, 0, _label) do
    State.invalidate(state, "division by zero")
  end

  defp divide(state = %State{current_value: current}, value, label) do
    State.update(state, current / value, label: label)
  end
end
