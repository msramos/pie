defmodule Pie do
  @moduledoc false

  alias Pie.State

  defdelegate pipeline(data, options \\ []), to: State, as: :new
  defdelegate finish(state), to: State, as: :result
end
