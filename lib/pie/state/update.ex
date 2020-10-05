defmodule Pie.State.Update do
  @moduledoc """
  State update record handling
  """
  defstruct label: nil, index: 0, previous_value: nil, new_value: nil

  @typedoc """
  This struct keeps the data of one single state update
  """
  @type t :: %__MODULE__{
          label: String.t() | :atom | nil,
          index: non_neg_integer(),
          previous_value: any(),
          new_value: any()
        }
end
