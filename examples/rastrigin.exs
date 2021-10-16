# See notebooks/rastrigin_intro.livemd for more insights

Mix.install([
  {:meow, path: Path.expand("..", __DIR__)},
  # or in a standalone script: {:meow, "~> 0.1.0-dev", github: "jonatanklosko/meow"},
  {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "nx", override: true},
  {:exla, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "exla"}
])

defmodule Rastrigin do
  import Nx.Defn
  alias Meow.{Model, Pipeline, Population, Topology}

  def size, do: 100

  @two_pi 2 * :math.pi()

  @defn_compiler EXLA
  defn evaluate(genomes) do
    sums =
      (10 + Nx.power(genomes, 2) - 10 * Nx.cos(genomes * @two_pi))
      |> Nx.sum(axes: [1])

    -sums
  end

  def model_simple() do
    Model.new(&evaluate/1)
    |> Model.add_pipeline(
      MeowNx.Ops.init_real_random_uniform(100, size(), -5.12, 5.12),
      Pipeline.new([
        MeowNx.Ops.selection_tournament(1.0),
        MeowNx.Ops.crossover_uniform(0.5),
        MeowNx.Ops.mutation_replace_uniform(0.001, -5.12, 5.12),
        MeowNx.Ops.log_best_individual(),
        Meow.Ops.max_generations(5_000)
      ])
    )
  end

  def model_simple_multi() do
    Model.new(&evaluate/1)
    |> Model.add_pipeline(
      MeowNx.Ops.init_real_random_uniform(100, size(), -5.12, 5.12),
      Pipeline.new([
        MeowNx.Ops.selection_tournament(1.0),
        MeowNx.Ops.crossover_uniform(0.5),
        MeowNx.Ops.mutation_shift_gaussian(0.001),
        Meow.Ops.emigrate(MeowNx.Ops.selection_tournament(5), &Topology.ring/2, interval: 10),
        Meow.Ops.immigrate(&MeowNx.Ops.selection_natural(&1), interval: 10),
        MeowNx.Ops.log_best_individual(),
        Meow.Ops.max_generations(5_000)
      ]),
      duplicate: 3
    )
  end

  def model_branching() do
    Model.new(&evaluate/1)
    |> Model.add_pipeline(
      MeowNx.Ops.init_real_random_uniform(100, size(), -5.12, 5.12),
      Pipeline.new([
        # Here the pipeline branches out into two sub-pipelines,
        # which results are then joined into a single population.
        Meow.Ops.split_join(
          &Population.duplicate(&1, 2),
          [
            Pipeline.new([
              MeowNx.Ops.selection_natural(0.2)
            ]),
            Pipeline.new([
              MeowNx.Ops.selection_tournament(0.8),
              MeowNx.Ops.crossover_blend_alpha(0.5),
              MeowNx.Ops.mutation_shift_gaussian(0.001)
            ])
          ],
          &Population.concatenate/1
        ),
        MeowNx.Ops.log_best_individual(),
        Meow.Ops.max_generations(5_000)
      ])
    )
  end
end

# Pick one

# model = Rastrigin.model_simple()
# model = Rastrigin.model_simple_multi()
model = Rastrigin.model_branching()
Meow.Runner.run(model)
