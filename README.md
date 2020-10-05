# Pie: Pipelines In Elixir

A library to create trackable pipelines in Elixir.

## The problem

Let's start with a simple example: a pipeline of math operations. If we have
something like this:

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

## Using pie

We could use `pie` here and keep our beloved function pipe from the first
example and have more information about failures:


```elixir
defmodule Example3 do
  alias Pie.State

  def run do
    10
    |> Pie.pipeline(track_updates: true)
    |> add(20)
    |> subtract(5)
    |> divide(0)
    |> Pie.finish()
  end

  def add(state = %State{current_value: a}, b),
    do: State.update(state, a + b, label: "adding values")

  def subtract(state = %State{current_value: a}, b),
    do: State.update(state, a - b, label: "subtracting value")

  def divide(state, 0), do: State.invalidate(state, "division by zero")
  def divide(state = %State{current_value: a}, b), do: State.update(state, a / b)
end
```

Now if we run our `Example3.run/0`, we'll have much more details about what
happened:

```elixir
{:error,
 %Pie.State{
   current_value: 25,
   error: "division by zero",
   initial_value: 10,
   track_updates?: true,
   update_count: 2,
   updates: [
     %Pie.State.Update{
       index: 1,
       label: "subtracting value",
       new_value: 25,
       previous_value: 30
     },
     %Pie.State.Update{
       index: 0,
       label: "adding values",
       new_value: 30,
       previous_value: 10
     }
   ],
   valid?: false
 }}
```

The idea is quite simple: we wrap the original value on a `Pie.State` struct
and, from there, we can invalidate the state of our pipeline at any moment.
Also, at any moment we can get the result of our state:

```elixir
defmodule Example4 do
  alias Pie.State

  def do_stuff(value) do
    value
    |> Pie.pipeline()
    |> revert()
    |> upcase()
    |> add_suffix("hey, ho!")
    |> Pie.finish()
  end

  def revert(state = %State{current_value: value}) do
    reverted = String.reverse(value)
    State.update(state,reverted, label: "reverting #{value}")
  end

  def upcase(state = %State{current_value: value}) do
    State.update(state, String.upcase(value), label: "upcasing #{value}")
  end

  def add_suffix(state = %State{current_value: value}, suffix) do
    State.update(state, "#{value} #{suffix}", label: "adding suffix to #{value}")
  end
end
```

Calling `Example4.do_stuff("john snow")` will return the following value:

```
{:ok, "WONS NHOJ hey, ho!"}
```

## Installation

When available on `hex.pm`, this package can be installed by adding `pie` to
your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pie, "~> 0.1.0"}
  ]
end
```

