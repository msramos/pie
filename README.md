# Pie: Pipelines In Elixir

A library to create trackable and stateful pipelines in Elixir.

The main goals of this project are:
- A standartized way to build ok and error tuples when using pipes
- A single way to build data transformation
- Add more context to failures

**Using it as state wrapper**

This is the easiest way to buid pipelines with `pie`: you use `Pie.wrap_state/2`
to create your initial state, pipe in a bunch of functions finally call
`Pie.eval_state/1` to evaluate the latest state to determine your result.

The step functions are must adhere to the following requirements:
- It MUST accept at least one argument
- This argument will be a `Pie.State` struct
- It MUST return an updated state in the form of a `Pie.State` struct

Here is one very basic example:

```elixir
defmodule Example do
  import Pie
  alias Pie.State

  def do_math(number, add_by, div_by) do
    number
    |> wrap_state(track_updates: true)
    |> add(add_by)
    |> divide(div_by)
    |> double()
    |> eval_state()
  end

  defp add(state = %{current_value: value}, arg) do
    State.update(state, value + arg, label: "adding: #{value} + #{arg}")
  end

  defp double(state = %{current_value: value}) do
    State.update(state, value * 2, label: "doubling #{value}")
  end

  defp divide(state = %{current_value: value}, divisor) when divisor != 0 do
    State.update(state, value / divisor, label: "division: #{value}/#{divisor}")
  end

  defp divide(state = %{current_value: value}, _zero) do
    State.invalidate(state, "tried to divide #{value} by zero")
  end
end
```

Running `Example.do_math(5, 2, 4)` will return `{:ok, 3.5}`. However, if we try
to do something illegal, we'll get a very descriptive error:

```elixir
{:error,
 %Pie.State{
   current_value: 7,
   error: "tried to divide 7 by zero",
   initial_value: 5,
   track_updates?: true,
   update_count: 1,
   updates: [
     %Pie.State.Update{
       index: 0,
       label: "adding: 5 + 2",
       new_value: 7,
       previous_value: 5
     }
   ],
   valid?: false
 }}
```

Notice that the after the state was invalidated the function
`Pie.State.update/2` will have no effect on it.

**Using the pipeline builder**

On our previous example used `Pie.wrap_state/2` and `Pie.eval_state/1` functions
to keep track of our pipeline state.

If you want more control and more context about what is happening inside the
pipeline you can use the pipeline builder to create a more complete (although
more complex) solution.

In this mode your functions MUST accept exactly two args: the state and the
context. The context is whatever value you give to `Pie.add_step` function.

Here is our example, revisited:

```elixir
defmodule Example do
  import Pie
  alias Pie.State

  def do_math(number, add_by, div_by) do
    number
    |> new_pipeline(track_steps: true)
    |> add_step(&add/2, add_by, label: "step: add")
    |> add_step(&divide/2, div_by, label: "step: divide")
    |> add_step(&double/2, nil, label: "step: double")
    |> run_pipeline()
  end

  defp add(state = %{current_value: value}, arg) do
    State.update(state, value + arg, label: "adding: #{value} + #{arg}")
  end

  defp double(state = %{current_value: value}, _context) do
    State.update(state, value * 2, label: "doubling #{value}")
  end

  defp divide(state = %{current_value: value}, divisor) when divisor != 0 do
    State.update(state, value / divisor, label: "division: #{value}/#{divisor}")
  end

  defp divide(state = %{current_value: value}, _zero) do
    State.invalidate(state, "tried to divide #{value} by zero")
  end
end
```

Again, running `Example.do_math(5, 2, 4)` will return `{:ok, 3.5}`, as in the
first example. However, look at the returned value when we try to divide
by zero again by calling `Example.do_math(5, 2, 0)`:

```elixir
{:error,
 %Pie.Pipeline{
   executed?: true,
   executed_steps: [
     %Pie.Pipeline.Step{
       callback: #Function<2.43584920/2 in Example."-fun.double/2-">,
       context: nil,
       executed?: false,
       failed?: false,
       input: 7,
       label: "step: double",
       output: 7
     },
     %Pie.Pipeline.Step{
       callback: #Function<1.43584920/2 in Example."-fun.divide/2-">,
       context: 0,
       executed?: true,
       failed?: true,
       input: 7,
       label: "step: divide",
       output: nil
     },
     %Pie.Pipeline.Step{
       callback: #Function<0.43584920/2 in Example."-fun.add/2-">,
       context: 2,
       executed?: true,
       failed?: false,
       input: 5,
       label: "step: add",
       output: 7
     }
   ],
   state: %Pie.State{
     current_value: 7,
     error: "tried to divide 7 by zero",
     initial_value: 5,
     track_updates?: false,
     update_count: 1,
     updates: [],
     valid?: false
   },
   step_queue: {[], []},
   track_steps?: true
 }}
```

With this information now it is possible to know:
- Which steps were executed
- Which step have failed
- A description of the error
- The input and output of each step

## Why do something like pie?

Let's start go back to our first example: a pipeline of math operations. If we 
have something like this:

```elixir
defmodule Example1 do
  def run do
    10
    |> add(20)
    |> subtract(5)
    |> divide(0)      # this will explode
  end

  def add(a, b), do: a + b
  def subtract(a, b), do: a - b
  def divide(_a, 0), do: raise("division by zero")
  def divide(a, b), do: a / b
end
```

If you execute `Example.run/0`, you'll get the following error:

```
** (RuntimeError) division by zero
```

Not really helpful, right? Of course we could use a `with` clause and change our
functions a little bit to handle this scenario, something like this:

```elixir
defmodule Example2 do
  def run do
    with {:ok, v1} <- add(10, 20),
         {:ok, v2} <- subtract(v1, 5),
         {:ok, v3} <- divide(v2, 0) do
      {:ok, v3}
    end
  end

  def add(a, b), do: {:ok, a + b}
  def subtract(a, b), do: {:ok, a - b}
  def divide(a, b) when b != 0, do: {:ok, a / b}
  def divide(_a, _b), do: {:error, "division by zero"}
end
```

Running `Example2.run/0` will give us the following result:

```elixir
{:error, "division by zero"}
```

Much better! However our `with` block started to become big and as our project
starts to grow it may become filled with rules to a point that starts to be
really hard to read. Also, if instead of hardcoded values we had actual function
args, it becomes hard to determine where is the bad arg if we have several calls
to a function that returns the same error message:

```elixir
with {:ok, v1} <- add(a, b),
      {:ok, v2} <- subtract(v1, c),
      {:ok, v3} <- divide(v2, d),     # the error could happen here
      {:ok, v4} <- divide(v3, e) do   # or here
  {:ok, v4}
end
```

## Installation

When available on `hex.pm`, this package can be installed by adding `pie` to
your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pie, ">= 0.0.0"}
  ]
end
```