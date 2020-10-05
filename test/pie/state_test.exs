defmodule Pie.StateTest do
  use ExUnit.Case, async: true

  alias Pie.State

  @sut State

  describe "new/1" do
    test "creates a new valid state with the given data" do
      data = "this is my data"

      result = @sut.new(data)

      assert result == %State{
               initial_value: data,
               current_value: data,
               valid?: true,
               error: nil
             }
    end
  end

  describe "update/2" do
    test "updates the value of a valid state" do
      state = %State{valid?: true, initial_value: 10, current_value: 10}

      updated_state = @sut.update(state, 42)

      assert updated_state.current_value == 42
      assert updated_state.initial_value == 10
    end

    test "does not update the value of an invalid state" do
      state = %State{valid?: false, initial_value: 10, current_value: 10}

      updated_state = @sut.update(state, 42)

      assert updated_state.current_value == 10
      assert updated_state.initial_value == 10
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

  describe "result/1" do
    test "returns an {:ok, value} tuple when the state is valid" do
      state = %State{valid?: true, initial_value: 10, current_value: 42}

      result = @sut.result(state)

      assert result == {:ok, 42}
    end

    test "returns an {:error, state} tuple when the state is invalid" do
      state = %State{
        valid?: false,
        initial_value: 10,
        current_value: 42,
        error: "this is not valid"
      }

      result = @sut.result(state)

      assert result == {:error, state}
    end
  end
end
