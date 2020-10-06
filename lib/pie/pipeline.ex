defmodule Pie.Pipeline do
  @moduledoc """
  Pipeline handling.

  A pipeline consists of a state and several steps. When executed, the updated
  stated will be passed to each step, in order, until all of them are executed.
  At the end, the final version of the state will be evaluated and returned.
  """
  defstruct step_queue: :queue.new(),
            executed_steps: [],
            state: nil,
            executed?: false,
            track_steps?: false

  alias Pie.State
  alias Pie.Pipeline.Step

  @typedoc """
  A struct to hold information about the pipeline
  """
  @type t :: %__MODULE__{
          step_queue: :queue.queue(Step.t()),
          executed_steps: [Step.t()],
          state: State.t(),
          executed?: boolean(),
          track_steps?: boolean()
        }

  @typedoc """
  Returns the result of the pipeline execution
  """
  @type result :: {:ok, any()} | {:error, t()}

  @doc """
  Creates a new pipeline with an empty state
  """
  @spec new(input :: any(), options :: Keyword.t()) :: t()
  def new(input, options \\ []) do
    %__MODULE__{
      state: State.new(input, options),
      step_queue: :queue.new(),
      track_steps?: options[:track_steps] == true
    }
  end

  @doc """
  Adds a step into the pipeline queue.
  """
  @spec step(pipeline :: t(), step_fun :: fun(), context :: any(), options :: Keyword.t()) :: t()
  def step(pipeline = %__MODULE__{}, step_fun, context \\ nil, options \\ [])
      when is_function(step_fun) do
    steps =
      step_fun
      |> Step.new(context, options)
      |> :queue.in(pipeline.step_queue)

    %__MODULE__{pipeline | step_queue: steps}
  end

  @doc """
  Executes a pipeline and evalutes its state after all steps were applied
  """
  @spec run(t()) :: State.result()
  def run(pipeline = %__MODULE__{}) do
    pipeline = execute_steps(pipeline)

    case State.eval(pipeline.state) do
      result = {:ok, _result} ->
        result

      _error ->
        {:error, pipeline}
    end
  end

  defp execute_steps(pipeline) do
    case :queue.out(pipeline.step_queue) do
      {{:value, step}, queue} ->
        {updated_step, updated_state} = Step.execute(step, pipeline.state)

        steps = if pipeline.track_steps?, do: [updated_step | pipeline.executed_steps], else: []

        updated_pipeline = %__MODULE__{
          pipeline
          | step_queue: queue,
            executed_steps: steps,
            state: updated_state
        }

        execute_steps(updated_pipeline)

      {:empty, _queue} ->
        %__MODULE__{pipeline | executed?: true}
    end
  end
end
