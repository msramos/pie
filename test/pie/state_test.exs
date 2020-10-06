defmodule Pie.StateTest do
  use ExUnit.Case, async: true

  alias Pie.State
  alias Pie.State.Update

  @sut State

  describe "new/2" do
    test "creates a new valid state with the given data" do
      data = "this is my data"

      result = @sut.new(data)

      assert result == %State{
               initial_value: data,
               current_value: data,
               valid?: true,
               error: nil,
               track_updates?: false
             }
    end

    test "creates a new valid state with the given data and with :track_updates option" do
      data = "this is my data"

      result = @sut.new(data, track_updates: true)

      assert result == %State{
               initial_value: data,
               current_value: data,
               valid?: true,
               error: nil,
               track_updates?: true
             }
    end
  end

  describe "update/3" do
    test "updates the value of a valid state" do
      state = %State{valid?: true, initial_value: 10, current_value: 10}

      updated_state = @sut.update(state, 42)

      assert updated_state.current_value == 42
      assert updated_state.initial_value == 10
    end

    test "updates the updates_count of a state" do
      state = %State{valid?: true, initial_value: 10, current_value: 10}

      updated_state = @sut.update(state, 12)
      assert updated_state.update_count == 1

      updated_state = @sut.update(updated_state, 13)
      assert updated_state.update_count == 2
    end

    test "does not update the value or the updated_count of an invalid state" do
      state = %State{valid?: false, initial_value: 10, current_value: 11, update_count: 1}

      updated_state = @sut.update(state, 42)

      assert updated_state.current_value == 11
      assert updated_state.initial_value == 10
      assert updated_state.update_count == 1
    end

    test "tracks state updates with labels when :track_updates? options is set to true" do
      state = %State{
        valid?: true,
        initial_value: 10,
        current_value: 10,
        update_count: 0,
        track_updates?: true
      }

      updated_state = @sut.update(state, 11, label: "simple state change")

      assert updated_state.updates == [
               %Update{label: "simple state change", previous_value: 10, new_value: 11}
             ]
    end

    test "tracks state updates without labels when :track_updates? options is set to true" do
      state = %State{
        valid?: true,
        initial_value: 10,
        current_value: 10,
        update_count: 0,
        track_updates?: true
      }

      updated_state = @sut.update(state, 11)

      assert updated_state.updates == [%Update{previous_value: 10, new_value: 11}]
    end
  end

  describe "invalidate/2" do
    test "sets the error and invalidates the state" do
      state = %State{valid?: true, initial_value: 10, current_value: 42}

      updated_state = @sut.invalidate(state, "this is not valid")

      assert updated_state.valid? == false
      assert updated_state.error == "this is not valid"
      assert updated_state.initial_value == 10
      assert updated_state.current_value == 42
    end
  end

  describe "eval/1" do
    test "returns an {:ok, value} tuple when the state is valid" do
      state = %State{valid?: true, initial_value: 10, current_value: 42}

      result = @sut.eval(state)

      assert result == {:ok, 42}
    end

    test "returns an {:error, state} tuple when the state is invalid" do
      state = %State{
        valid?: false,
        initial_value: 10,
        current_value: 42,
        error: "this is not valid"
      }

      result = @sut.eval(state)

      assert result == {:error, state}
    end
  end
end
