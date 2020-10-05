defmodule Pie.State do
  @moduledoc """
  Pipeline state handling.

  - At any given moment the state can be evaluated to extract a result
  - An invalid pipeline can not be updated
  """
  defstruct valid?: true,
            track_updates?: false,
            update_count: 0,
            updates: [],
            initial_value: nil,
            current_value: nil,
            error: nil

  alias Pie.State.Update

  @typedoc """
  A struct to hold the state of the pipeline.
  """
  @type t :: %__MODULE__{
          valid?: true | false,
          update_count: non_neg_integer(),
          updates: [Update.t()],
          track_updates?: true | false,
          current_value: any(),
          initial_value: any(),
          error: any()
        }

  @doc """
  Creates a new valid state from the given data.
  """
  @spec new(any(), Keyword.t()) :: t()
  def new(data, opts \\ []) do
    %__MODULE__{
      current_value: data,
      initial_value: data,
      track_updates?: opts[:track_updates] || false,
      updates: [],
      update_count: 0
    }
  end

  @doc """
  Updates the state of the pipeline. It does not update an invalid state.
  """
  @spec update(t(), any(), Keyword.t()) :: t()
  def update(state, value, opts \\ [])

  def update(state = %__MODULE__{valid?: true, track_updates?: false}, value, _opts) do
    %__MODULE__{state | current_value: value, update_count: state.update_count + 1}
  end

  def update(state = %__MODULE__{valid?: true, track_updates?: true}, value, opts)
      when is_list(opts) do
    updates = get_updates(state, value, opts)

    %__MODULE__{
      state
      | current_value: value,
        updates: updates,
        update_count: state.update_count + 1
    }
  end

  def update(state = %__MODULE__{}, _value, _opts) do
    state
  end

  defp get_updates(state = %__MODULE__{}, new_value, opts) do
    update = %Update{
      previous_value: state.current_value,
      new_value: new_value,
      index: state.update_count,
      label: opts[:label]
    }

    [update | state.updates]
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
  @spec result(t()) :: {:ok, any()} | {:error, t()}
  def result(state)

  def result(%__MODULE__{valid?: true, current_value: value}) do
    {:ok, value}
  end

  def result(state = %__MODULE__{}) do
    {:error, state}
  end
end
