defmodule Pie do
  @moduledoc false

  alias Pie.{Pipeline, State}

  @doc """
  Wraps `data` and returns a new `Pie.State` struct.
  See `Pie.State.new/2`
  """
  defdelegate wrap_state(data, options \\ []), to: State, as: :new

  @doc """
  Evalutes the state from `state` and returns its result.

  See `Pie.State.eval/1`
  """
  defdelegate eval_state(state), to: State, as: :eval

  @doc """
  Creates a new pipeline for `data`.

  See `Pie.Pipeline.new/2`
  """
  defdelegate new_pipeline(data, options \\ []), to: Pipeline, as: :new

  @doc """
  Adds a new pipeline step for `pipeline`.

  See `Pie.Pipeline.step/4`
  """
  defdelegate add_step(pipeline, function, context \\ nil, options \\ []),
    to: Pipeline,
    as: :step

  @doc """
  Executes a pipeline and returns its result.

  See `Pie.Pipeline.run/1`
  """
  defdelegate run_pipeline(pipeline), to: Pipeline, as: :run
end
