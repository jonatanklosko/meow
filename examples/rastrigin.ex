defmodule Rastrigin do
  import Nx.Defn

  alias Meow.Model
  alias Meow.Generic.{Termination}
  alias MeowNx.{Selection, Crossover, Mutation, Initializer}

  def model() do
    Model.new(
      initializer: Initializer.real_random_uniform(min: -5.15, max: 5.12, n: 1000, size: 1000),
      evaluate: &evaluate/1
    )
    |> Model.add_pipeline(
      Pipeline.new([
        Selection.tournament(n: 1000),
        Crossover.uniform(probability: 0.5),
        Mutation.replace_random_uniform(min: -5.12, max: 5.12, probability: 0.001),
        Termination.max_generations(n: 10)
      ])
    )
  end

  @defn_compiler EXLA
  defn evaluate(population) do
    sums =
      (10 + Nx.power(population, 2) - 10 * Nx.cos(population * 2 * 3.141592653589793))
      |> Nx.sum(axes: [1])

    -sums
  end
end

:timer.tc(fn -> Runner.run(Rastrigin.model()) end)
