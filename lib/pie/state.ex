defmodule Pie.State do
  @moduledoc """
  Pipeline state handling.

  - At any given moment the state can be evaluated to extract a result
  - An invalid pipeline can not be updated
  """
  defstruct valid?: true, initial_value: nil, current_value: nil, error: nil

  @typedoc """
  A struct to hold the state of the pipeline.
  """
  @type t :: %__MODULE__{
          valid?: true | false,
          current_value: any(),
          initial_value: any(),
          error: any()
        }

  @doc """
  Creates a new valid state from the given data.
  """
  @spec new(any()) :: t()
  def new(data) do
    %__MODULE__{
      current_value: data,
      initial_value: data
    }
  end

  @doc """
  Updates the state of the pipeline. It does not update an invalid state.
  """
  @spec update(t(), any()) :: t()
  def update(state, value)

  def update(state = %__MODULE__{valid?: true}, value) do
    %__MODULE__{state | current_value: value}
  end

  def update(state = %__MODULE__{}, _value) do
    state
  end

  @doc """
  Invalidates a state and sets its error
  """
  @spec invalidate(t(), any()) :: t()
  def invalidate(state = %__MODULE__{}, error) do
    %__MODULE__{state | valid?: false, error: error}
  end

  @doc """
  Returns an ok or error tuple depending on the value of the given state.
  """
  @spec result(t()) :: {:ok | :error, any()}
  def result(state)

  def result(%__MODULE__{valid?: true, current_value: value}) do
    {:ok, value}
  end

  def result(state = %__MODULE__{}) do
    {:error, state}
  end
end
