# To test this locally, run the script in separate shell sessions.
# Make sure to specify node name to enable distribution and pass
# the expected CLI arguments like this:
#
#   elixir --name leader@127.0.0.1 examples/distributed.exs leader worker@127.0.0.1
#
#   elixir --name worker@127.0.0.1 examples/distributed.exs worker

Mix.install([
  {:meow, "~> 0.1.0-dev", github: "jonatanklosko/meow"},
  {:nx, "~> 0.7.0"},
  {:exla, "~> 0.7.0"}
])

Nx.Defn.global_default_options(compiler: EXLA)

defmodule Problem do
  import Nx.Defn

  def size, do: 100

  @two_pi 2 * :math.pi()

  defn evaluate_rastrigin(genomes) do
    sums =
      (10 + Nx.pow(genomes, 2) - 10 * Nx.cos(genomes * @two_pi))
      |> Nx.sum(axes: [1])

    -sums
  end
end

algorithm =
  Meow.objective(&Problem.evaluate_rastrigin/1)
  |> Meow.add_pipeline(
    MeowNx.Ops.init_real_random_uniform(100, Problem.size(), -5.12, 5.12),
    Meow.pipeline([
      MeowNx.Ops.selection_tournament(1.0),
      MeowNx.Ops.crossover_uniform(0.5),
      MeowNx.Ops.mutation_shift_gaussian(0.001),
      Meow.Ops.emigrate(
        MeowNx.Ops.selection_tournament(5),
        &Meow.Topology.ring/2,
        interval: 10
      ),
      Meow.Ops.immigrate(
        &MeowNx.Ops.selection_natural(&1),
        interval: 10
      ),
      MeowNx.Ops.log_best_individual(),
      Meow.Ops.max_generations(1_000)
    ]),
    # Duplicate the pipeline, so that the algorithm
    # involves 4 populations
    duplicate: 4
  )

Meow.Distribution.init_from_cli_args!(fn nodes ->
  report = Meow.run(algorithm, nodes: nodes)
  report |> Meow.Report.format_summary() |> IO.puts()
end)
