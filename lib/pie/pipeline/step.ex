defmodule Pie.Pipeline.Step do
  @moduledoc """
  Pipeline step handling
  """
  defstruct context: nil,
            callback: nil,
            input: nil,
            output: nil,
            error: nil,
            executed?: false,
            failed?: false,
            label: nil

  alias Pie.State

  @typedoc """
  A struct to hold data about a pipeline step
  """
  @type t :: %__MODULE__{
          context: any(),
          callback: function(),
          input: any(),
          error: any(),
          output: any(),
          executed?: boolean(),
          failed?: boolean(),
          label: any()
        }
  @doc """
  Creates a new step
  """
  @spec new(function(), any(), Keyword.t()) :: t()
  def new(fun, context \\ nil, options \\ []) when is_function(fun) do
    %__MODULE__{
      callback: fun,
      context: context,
      label: options[:label]
    }
  end

  @doc """
  Executes the step and track the data about its input and output
  """
  @spec execute(t(), State.t(), boolean()) :: {t(), State.t()}
  def execute(step = %__MODULE__{executed?: false}, state, capture_error? \\ false) do
    case run_step(step, state, capture_error?) do
      {:ok, updated_state} ->
        failed? = state.valid? && !updated_state.valid?

        updated_step = %__MODULE__{
          step
          | input: state.current_value,
            output: if(failed?, do: nil, else: updated_state.current_value),
            executed?: state.valid?,
            failed?: failed?
        }

        {updated_step, updated_state}

      {:error, error} ->
        updated_state = State.invalidate(state, :error)

        updated_step = %__MODULE__{
          step
          | input: state.current_value,
            output: nil,
            executed?: true,
            failed?: true,
            error: error
        }

        {updated_step, updated_state}
    end
  end

  defp run_step(step, state, _capture_error = true) do
    try do
      run_step(step, state, false)
    rescue
      error -> {:error, error}
    end
  end

  defp run_step(step, state, _capture_error) do
    {:ok, step.callback.(state, step.context)}
  end
end
