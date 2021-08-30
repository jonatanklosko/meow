# Install Meow and Nx for numerical computing

Mix.install([
  {:meow, path: Path.expand("..", __DIR__)},
  # or in a standalone script: {:meow, "~> 0.1.0-dev", github: "jonatanklosko/meow"},
  {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "nx", override: true},
  {:exla, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "exla"},
  {:exla_precompiled, "~> 0.1.0-dev", github: "jonatanklosko/exla_precompiled"}
])

# Define the evaluation function, in this case using Nx to work with MeowNx

defmodule Problem do
  import Nx.Defn

  def size, do: 100

  @two_pi 2 * :math.pi()

  @defn_compiler EXLA
  defn evaluate_rastrigin(genomes) do
    sums =
      (10 + Nx.power(genomes, 2) - 10 * Nx.cos(genomes * @two_pi))
      |> Nx.sum(axes: [1])

    -sums
  end
end

# Define the evolutionary model (algorithm)

alias Meow.{Model, Pipeline}

model =
  Model.new(
    # Define how the population is initialized and what representation to use
    MeowNx.Init.real_random_uniform(100, Problem.size(), -5.12, 5.12),
    # Specify the evaluation function that we are trying to maximise
    &Problem.evaluate_rastrigin/1
  )
  |> Model.add_pipeline(
    # A single pipeline corresponds to a single population
    Pipeline.new([
      # Define a number of evolutionary steps that the population goes through
      MeowNx.Op.Selection.tournament(100),
      MeowNx.Op.Crossover.uniform(0.5),
      MeowNx.Op.Mutation.replace_uniform(0.001, -5.12, 5.12),
      MeowNx.Op.Metric.best_individual(),
      Meow.Op.Termination.max_generations(5_000)
    ])
  )

# Execute the above model

Meow.Runner.run(model)
