Mix.install([
  {:meow, path: Path.expand("..", __DIR__)},
  # or in a standalone script: {:meow, "~> 0.1.0-dev", github: "jonatanklosko/meow"},
  {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "nx", override: true},
  {:exla, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "exla"},
  {:exla_precompiled, "~> 0.1.0-dev", github: "jonatanklosko/exla_precompiled"}
])

# In "0-1 knapsnack problem" the objective is to pick a subset
# of objects, such that the total weight is within limit and the
# profit is maximised.

# This example comes from https://en.wikipedia.org/wiki/Knapsack_problem
# and the highest fitness (maximal possible profit) is 1270.

# We use the binary representation, where n-th gene indicates whether
# n-th object is in the subset.

defmodule Problem do
  import Nx.Defn

  @profits Nx.tensor([505, 352, 458, 220, 345, 414, 498, 545, 473, 543])
  @object_weights Nx.tensor([23, 26, 20, 18, 32, 27, 29, 26, 30, 27])
  @weight_limit Nx.tensor(67)

  def size, do: Nx.size(@profits)

  @defn_compiler EXLA
  defn evaluate_knapsack(genomes) do
    total_profit = Nx.dot(genomes, @profits)
    total_weight = Nx.dot(genomes, @object_weights)
    in_limit? = Nx.less_equal(total_weight, @weight_limit)
    Nx.select(in_limit?, total_profit, 0)
  end
end

alias Meow.{Model, Pipeline}

model =
  Model.new(
    MeowNx.Init.binary_random_uniform(100, Problem.size()),
    &Problem.evaluate_knapsack/1
  )
  |> Model.add_pipeline(
    Pipeline.new([
      MeowNx.Op.Selection.tournament(1.0),
      MeowNx.Op.Crossover.uniform(0.5),
      MeowNx.Op.Mutation.binary_replace_uniform(0.1),
      MeowNx.Op.Metric.best_individual(),
      Meow.Op.Termination.max_generations(100)
    ])
  )

Meow.Runner.run(model)
