Mix.install([
  {:meow, path: Path.expand("..", __DIR__)},
  # or in a standalone script: {:meow, "~> 0.1.0-dev", github: "jonatanklosko/meow"},
  {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "nx", override: true},
  {:exla, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "exla"},
  {:exla_precompiled, "~> 0.1.0-dev", github: "jonatanklosko/exla_precompiled"}
])

# In "one max" problem the objective is simply to maximise
# the number of ones in a binary string.

defmodule Problem do
  import Nx.Defn

  def size, do: 100

  @defn_compiler EXLA
  defn evaluate_one_max(genomes) do
    Nx.sum(genomes, axes: [1])
  end
end

alias Meow.{Model, Pipeline}

model =
  Model.new(
    MeowNx.Op.Init.binary_random_uniform(100, Problem.size()),
    &Problem.evaluate_one_max/1
  )
  |> Model.add_pipeline(
    Pipeline.new([
      MeowNx.Op.Selection.tournament(1.0),
      MeowNx.Op.Crossover.uniform(0.5),
      MeowNx.Op.Mutation.binary_replace_uniform(0.001),
      MeowNx.Op.Metric.best_individual(),
      Meow.Op.Termination.max_generations(100)
    ])
  )

Meow.Runner.run(model)
