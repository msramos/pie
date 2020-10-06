defmodule PieTest do
  use ExUnit.Case
  doctest Pie

  alias Pie.Pipeline
  alias Pie.Pipeline.Step
  alias Pie.State
  alias Pie.State.Update

  @sut Pie

  describe "wrap_state/eval_state" do
    test "a succesful pipeline returns an ok tuple" do
      result =
        10
        |> @sut.wrap_state()
        |> add(10)
        |> add(2)
        |> divide(2)
        |> @sut.eval_state()

      assert result == {:ok, 11}
    end

    test "a failed pipeline returns an error tuple with the latest state" do
      result =
        10
        |> @sut.wrap_state()
        |> add(10)
        |> divide(0)
        |> @sut.eval_state()

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
      {:error, result} =
        10
        |> @sut.wrap_state(track_updates: true)
        |> add(15, "adding 15")
        |> add(2)
        |> divide(0, "trying the impossible")
        |> @sut.eval_state()

      assert result == %State{
               error: "division by zero",
               updates: [
                 %Update{previous_value: 25, new_value: 27, index: 1},
                 %Update{label: "adding 15", previous_value: 10, new_value: 25, index: 0}
               ],
               current_value: 27,
               initial_value: 10,
               update_count: 2,
               valid?: false,
               track_updates?: true
             }
    end
  end

  describe "new/step/run" do
    test "executes a pipeline in order" do
      result =
        @sut.new_pipeline([10])
        |> @sut.pipeline_step(&step_append/2, 11)
        |> @sut.pipeline_step(&step_append/2, 12)
        |> @sut.run_pipeline()

      assert result == {:ok, [12, 11, 10]}
    end

    test "a failed pipeline returns the error tuple with the pipeline" do
      {:error, pipeline} =
        @sut.new_pipeline([10], track_updates: true, track_steps: true)
        |> @sut.add_step(&step_append/2, 11)
        |> @sut.add_step(&step_invalidate/2)
        |> @sut.run_pipeline()

      step_1 = Step.new(&step_append/2, 11)
      step_2 = Step.new(&step_invalidate/2)

      assert pipeline == %Pipeline{
               executed?: true,
               executed_steps: [
                 %Step{step_2 | executed?: true, failed?: true, input: [11, 10], output: nil},
                 %Step{
                   step_1
                   | executed?: true,
                     failed?: false,
                     input: [10],
                     output: [11, 10],
                     context: 11
                 }
               ],
               track_steps?: true,
               state: %State{
                 error: "oh no this is not valid",
                 initial_value: [10],
                 current_value: [11, 10],
                 update_count: 1,
                 track_updates?: true,
                 updates: [
                   %Update{previous_value: [10], new_value: [11, 10], index: 0}
                 ],
                 valid?: false
               }
             }
    end
  end

  defp step_append(state = %State{current_value: current}, context) do
    State.update(state, [context | current])
  end

  defp step_invalidate(state, _context) do
    State.invalidate(state, "oh no this is not valid")
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
