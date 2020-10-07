defmodule Pie.PipelineTest do
  use ExUnit.Case, async: true

  alias Pie.Pipeline
  alias Pie.Pipeline.Step
  alias Pie.State

  @sut Pipeline

  describe "new/2" do
    test "creates a new empty pipeline with empty state" do
      expected = %Pipeline{
        step_queue: :queue.new(),
        state: State.new("sample data")
      }

      result = @sut.new("sample data")

      assert result == expected
    end

    test "creates a new empty pipeline with empty state and trackable updates" do
      expected = %Pipeline{
        step_queue: :queue.new(),
        state: State.new("sample data", track_updates: true)
      }

      result = @sut.new("sample data", track_updates: true)

      assert result == expected
    end
  end

  describe "step/2" do
    test "adds functions to the pipelines' steps" do
      pipeline = %Pipeline{
        step_queue: :queue.new(),
        state: State.new(0)
      }

      step_fun = fn state -> state end
      step = Step.new(step_fun, 123, label: "a step")

      expected = %Pipeline{pipeline | step_queue: :queue.in(step, pipeline.step_queue)}

      updated_pipeline = @sut.step(pipeline, step_fun, 123, label: "a step")

      assert updated_pipeline == expected
    end
  end

  describe "run/1" do
    test "executes the pipeline and returns a succesful result" do
      queue = :queue.new()

      step_fun = fn s = %{current_value: a = [v | _]}, _context ->
        State.update(s, [v + 1 | a])
      end

      step = Step.new(step_fun, nil, label: "this is a step")

      pipeline = %Pipeline{
        step_queue: :queue.in(step, queue),
        state: State.new([0])
      }

      result = @sut.run(pipeline)

      assert result == {:ok, [1, 0]}
    end

    test "executes the pipeline and returns and error tuple with the pipeline state" do
      queue = :queue.new()
      step_fun = fn s, _context -> State.invalidate(s, "oh no") end
      step = Step.new(step_fun, nil, label: "failing step")

      pipeline = %Pipeline{
        step_queue: :queue.in(step, queue),
        state: State.new(:whatever)
      }

      expected = %Pipeline{
        executed?: true,
        step_queue: :queue.new(),
        state: %State{
          valid?: false,
          current_value: :whatever,
          initial_value: :whatever,
          error: "oh no"
        }
      }

      result = @sut.run(pipeline)

      assert result == {:error, expected}
    end

    test "keeps track of executed steps with option track_steps?: true" do
      step1_fun = fn s, _context -> State.update(s, :ok) end
      step1 = Step.new(step1_fun, nil, label: "working step")

      step2_fun = fn s, _context -> State.invalidate(s, "oh no") end
      step2 = Step.new(step2_fun, nil, label: "failing step")

      queue = :queue.new()
      queue = :queue.in(step1, queue)
      queue = :queue.in(step2, queue)

      pipeline = %Pipeline{
        track_steps?: true,
        step_queue: queue,
        state: State.new(:whatever)
      }

      expected = %Pipeline{
        pipeline
        | executed?: true,
          step_queue: :queue.new(),
          executed_steps: [
            %Step{
              executed?: true,
              failed?: true,
              callback: step2_fun,
              input: :ok,
              output: nil,
              label: "failing step"
            },
            %Step{
              executed?: true,
              failed?: false,
              callback: step1_fun,
              input: :whatever,
              output: :ok,
              label: "working step"
            }
          ],
          state: %State{
            valid?: false,
            current_value: :ok,
            initial_value: :whatever,
            error: "oh no",
            update_count: 1
          }
      }

      result = @sut.run(pipeline)

      assert result == {:error, expected}
    end

    test "capture exceptions with the option capture_errors: true" do
      # this step will multiply the value of the state by 2
      step1_fun = fn s = %{current_value: v}, c -> State.update(s, v * c) end
      step1 = Step.new(step1_fun, 2, label: "working step")

      # this step will divide the value of the state by 0, causing an error
      step2_fun = fn s = %{current_value: v}, c -> State.update(s, v / c) end
      step2 = Step.new(step2_fun, 0, label: "failing step")

      queue = :queue.new()
      queue = :queue.in(step1, queue)
      queue = :queue.in(step2, queue)

      pipeline = %Pipeline{
        track_steps?: true,
        capture_errors?: true,
        step_queue: queue,
        state: State.new(10)
      }

      expected = %Pipeline{
        pipeline
        | executed?: true,
          step_queue: :queue.new(),
          executed_steps: [
            %Step{
              executed?: true,
              failed?: true,
              error: %ArithmeticError{message: "bad argument in arithmetic expression"},
              callback: step2_fun,
              input: 20,
              context: 0,
              output: nil,
              label: "failing step"
            },
            %Step{
              executed?: true,
              failed?: false,
              callback: step1_fun,
              context: 2,
              input: 10,
              output: 20,
              label: "working step"
            }
          ],
          state: %State{
            valid?: false,
            current_value: 20,
            initial_value: 10,
            error: :error,
            update_count: 1
          }
      }

      result = @sut.run(pipeline)

      assert result == {:error, expected}
    end
  end
end
