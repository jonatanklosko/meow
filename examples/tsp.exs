# Traveling Salesman Problem (TSP)
#
# For problem description and example data sets see
# https://people.sc.fsu.edu/~jburkardt/datasets/tsp/tsp.html
#
# Here we consider an example with 26 cities and the optimal total
# distance of 937.

Mix.install([
  {:meow, path: Path.expand("..", __DIR__)},
  # or in a standalone script: {:meow, "~> 0.1.0-dev", github: "jonatanklosko/meow"},
  {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "nx", override: true},
  {:exla, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "exla"},
  {:req, "~> 0.2.1"}
])

Nx.Defn.global_default_options(compiler: EXLA)

defmodule Problem do
  import Nx.Defn

  def load_distances(url) do
    %{body: text} = Req.get!(url)

    flat_distances =
      text
      |> String.split()
      |> Enum.map(&String.to_integer/1)

    size = flat_distances |> length() |> :math.sqrt() |> floor()

    distances =
      flat_distances
      |> Nx.tensor()
      |> Nx.reshape({size, size})

    {size, distances}
  end

  defn evaluate(permutations, distance) do
    {_n, length} = Nx.shape(permutations)

    shifted =
      Nx.concatenate(
        [
          Nx.slice_along_axis(permutations, 1, length - 1, axis: 1),
          Nx.slice_along_axis(permutations, 0, 1, axis: 1)
        ],
        axis: 1
      )

    edges = Nx.stack([permutations, shifted], axis: -1)

    total = distance |> Nx.gather(edges) |> Nx.sum(axes: [1])
    -total
  end
end

{tsp_size, distances} =
  Problem.load_distances("https://people.sc.fsu.edu/~jburkardt/datasets/tsp/fri26_d.txt")

algorithm =
  Meow.objective(&Problem.evaluate(&1, distances))
  |> Meow.add_pipeline(
    MeowNx.Ops.Permutation.init_permutation_random(300, tsp_size),
    Meow.pipeline([
      Meow.Ops.split_join([
        Meow.pipeline([
          MeowNx.Ops.selection_natural(0.2)
        ]),
        Meow.pipeline([
          MeowNx.Ops.selection_tournament(0.8),
          MeowNx.Ops.Permutation.crossover_order(),
          MeowNx.Ops.Permutation.mutation_inversion(0.5)
        ])
      ]),
      Meow.Ops.emigrate(MeowNx.Ops.selection_natural(5), &Meow.Topology.ring/2, interval: 10),
      Meow.Ops.immigrate(&MeowNx.Ops.selection_natural(&1), interval: 10),
      MeowNx.Ops.log_best_individual(),
      MeowNx.Ops.log_metrics(%{fitness_max: &MeowNx.Metric.fitness_max/2}, interval: 10),
      Meow.Ops.max_generations(150)
    ]),
    duplicate: 4
  )

report = Meow.run(algorithm)

report |> Meow.Report.format_summary() |> IO.puts()
