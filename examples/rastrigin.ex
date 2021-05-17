Mix.install([
  {:exla, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "exla"},
  {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "nx", override: true},
  {:benchee, "~> 1.0"},
  {:meow, path: __DIR__ |> Path.join("..") |> Path.expand()}
])

defmodule Rastrigin do
  import Nx.Defn
  alias Meow.{Model, Pipeline, Population, Topology}
  alias Meow.Op.{Termination, Flow, Multi}
  alias MeowNx.Init
  alias MeowNx.Op.{Selection, Crossover, Mutation}

  def model_simple() do
    Model.new(
      Init.real_random_uniform(20, 100, -5.12, 5.12),
      &evaluate/1
    )
    |> Model.add_pipeline(
      Pipeline.new([
        Selection.tournament(20),
        Crossover.uniform(0.5),
        Mutation.replace_uniform(0.001, -5.12, 5.12),
        Termination.max_generations(50_000)
      ])
    )
  end

  def model_simple_multi() do
    Model.new(
      Init.real_random_uniform(20, 100, -5.12, 5.12),
      &evaluate/1
    )
    |> Model.add_pipeline(
      Pipeline.new([
        Selection.tournament(20),
        Crossover.uniform(0.5),
        Mutation.replace_uniform(0.001, -5.12, 5.12),
        Multi.emigrate(Selection.tournament(2), &Topology.ring/2, interval: 10),
        Multi.immigrate(&Selection.natural(&1), interval: 10),
        Termination.max_generations(50)
      ]),
      duplicate: 3
    )
  end

  def model_branching() do
    Model.new(
      Init.real_random_uniform(20, 100, -5.12, 5.12),
      &evaluate/1
    )
    |> Model.add_pipeline(
      Pipeline.new([
        # Here the pipeline branches out into two sub-pipelines,
        # which results are then joined into a single population.
        Flow.split_join(
          &Population.duplicate(&1, 2),
          [
            Pipeline.new([
              Selection.tournament(4)
            ]),
            Pipeline.new([
              Selection.tournament(16),
              Crossover.uniform(0.5),
              Mutation.replace_uniform(0.001, -5.12, 5.12)
            ])
          ],
          &Population.concatenate/1
        ),
        Termination.max_generations(50_000)
      ])
    )
  end

  def model_if() do
    Model.new(
      Init.real_random_uniform(20, 100, -5.12, 5.12),
      &evaluate/1
    )
    |> Model.add_pipeline(
      Pipeline.new([
        Selection.tournament(20),
        Flow.if(
          fn population -> rem(population.generation, 2) == 0 end,
          Pipeline.new([
            Crossover.uniform(0.7)
          ]),
          Pipeline.new([
            Crossover.uniform(0.3)
          ])
        ),
        Mutation.replace_uniform(0.001, -5.12, 5.12),
        Termination.max_generations(50_000)
      ])
    )
  end

  @two_pi 2 * :math.pi()

  @defn_compiler EXLA
  defn evaluate(genomes) do
    sums =
      (10 + Nx.power(genomes, 2) - 10 * Nx.cos(genomes * @two_pi))
      |> Nx.sum(axes: [1])

    -sums
  end
end

model = Rastrigin.model_simple_multi()
:timer.tc(fn -> Meow.Runner.run(model) end) |> IO.inspect()
