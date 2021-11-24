# See notebooks/rastrigin_intro.livemd for more insights

Mix.install([
  {:meow, path: Path.expand("..", __DIR__)},
  # or in a standalone script: {:meow, "~> 0.1.0-dev", github: "jonatanklosko/meow"},
  {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "nx", override: true},
  {:exla, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "exla"}
])

Nx.Defn.global_default_options(compiler: EXLA)

defmodule Problem do
  import Nx.Defn

  def size, do: 100

  @two_pi 2 * :math.pi()

  defn evaluate(genomes) do
    sums =
      (10 + Nx.power(genomes, 2) - 10 * Nx.cos(genomes * @two_pi))
      |> Nx.sum(axes: [1])

    -sums
  end
end

model_linear =
  Meow.objective(&Problem.evaluate/1)
  |> Meow.add_pipeline(
    MeowNx.Ops.init_real_random_uniform(100, Problem.size(), -5.12, 5.12),
    Meow.pipeline([
      MeowNx.Ops.selection_tournament(1.0),
      MeowNx.Ops.crossover_uniform(0.5),
      MeowNx.Ops.mutation_replace_uniform(0.001, -5.12, 5.12),
      MeowNx.Ops.log_best_individual(),
      Meow.Ops.max_generations(5_000)
    ])
  )

model_multi =
  Meow.objective(&Problem.evaluate/1)
  |> Meow.add_pipeline(
    MeowNx.Ops.init_real_random_uniform(100, Problem.size(), -5.12, 5.12),
    Meow.pipeline([
      MeowNx.Ops.selection_tournament(1.0),
      MeowNx.Ops.crossover_uniform(0.5),
      MeowNx.Ops.mutation_shift_gaussian(0.001),
      Meow.Ops.emigrate(MeowNx.Ops.selection_tournament(5), &Meow.Topology.ring/2, interval: 10),
      Meow.Ops.immigrate(&MeowNx.Ops.selection_natural(&1), interval: 10),
      MeowNx.Ops.log_best_individual(),
      Meow.Ops.max_generations(5_000)
    ]),
    duplicate: 3
  )

model_branching =
  Meow.objective(&Problem.evaluate/1)
  |> Meow.add_pipeline(
    MeowNx.Ops.init_real_random_uniform(100, Problem.size(), -5.12, 5.12),
    Meow.pipeline([
      # Here the pipeline branches out into two sub-pipelines,
      # which results are then concatenation into a single population.
      Meow.Ops.split_join([
        Meow.pipeline([
          MeowNx.Ops.selection_natural(0.2)
        ]),
        Meow.pipeline([
          MeowNx.Ops.selection_tournament(0.8),
          MeowNx.Ops.crossover_blend_alpha(0.5),
          MeowNx.Ops.mutation_shift_gaussian(0.001)
        ])
      ]),
      MeowNx.Ops.log_best_individual(),
      Meow.Ops.max_generations(5_000)
    ])
  )

for {model, idx} <- Enum.with_index([model_linear, model_multi, model_branching]) do
  report = Meow.run(model)
  IO.puts("\n# Model #{idx + 1}\n")
  report |> Meow.Report.format_summary() |> IO.puts()
end
