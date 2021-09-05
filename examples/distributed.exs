# To test this locally, run the script in separate shell sessions.
# Make sure to specify node name to enable distribution and pass
# the expected CLI arguments like this:
#
#   elixir --name leader@127.0.0.1 examples/distributed.exs leader worker@127.0.0.1
#
#   elixir --name worker@127.0.0.1 examples/distributed.exs worker

Mix.install([
  {:meow, path: Path.expand("..", __DIR__)},
  # or in a standalone script: {:meow, "~> 0.1.0-dev", github: "jonatanklosko/meow"},
  {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "nx", override: true},
  {:exla, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "exla"},
  {:exla_precompiled, "~> 0.1.0-dev", github: "jonatanklosko/exla_precompiled"}
])

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

alias Meow.{Model, Pipeline}

model =
  Model.new(&Problem.evaluate_rastrigin/1)
  |> Model.add_pipeline(
    MeowNx.Op.Init.real_random_uniform(100, Problem.size(), -5.12, 5.12),
    Pipeline.new([
      MeowNx.Op.Selection.tournament(1.0),
      MeowNx.Op.Crossover.uniform(0.5),
      MeowNx.Op.Mutation.shift_gaussian(0.001),
      Meow.Op.Multi.emigrate(
        MeowNx.Op.Selection.tournament(5),
        &Meow.Topology.ring/2,
        interval: 10
      ),
      Meow.Op.Multi.immigrate(
        &MeowNx.Op.Selection.natural(&1),
        interval: 10
      ),
      MeowNx.Op.Metric.best_individual(),
      Meow.Op.Termination.max_generations(1_000)
    ]),
    # Duplicate the pipeline, so that the model
    # describes 4 populations
    duplicate: 4
  )

Meow.Distribution.init_from_cli_args!(fn nodes ->
  Meow.Runner.run(model, nodes: nodes)
end)
