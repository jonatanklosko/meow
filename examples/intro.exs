# Install Meow and Nx for numerical computing

Mix.install([
  {:meow, "~> 0.1.0-dev", github: "jonatanklosko/meow"},
  {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "nx", override: true},
  # To install EXLA you need a couple prerequisites (https://github.com/elixir-nx/nx/tree/main/exla#installation).
  # Also note that the first installation takes a long time, because it involves
  # compiling XLA from source. This will however be streamlined in the future,
  # once pre-compiled binaries are available as part of EXLA.
  {:exla, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "exla"}
])

# Define the evaluation function, in this case using Nx to work with MeowNx

defmodule Problem do
  import Nx.Defn

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
    MeowNx.Init.real_random_uniform(100, 100, -5.12, 5.12),
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
