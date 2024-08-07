# In "one max" problem the objective is simply to maximise the number
# of ones in a binary string.

Mix.install([
  {:meow, "~> 0.1.0-dev", github: "jonatanklosko/meow"},
  {:nx, "~> 0.7.0"},
  {:exla, "~> 0.7.0"}
])

Nx.Defn.global_default_options(compiler: EXLA)

defmodule Problem do
  import Nx.Defn

  def size, do: 100

  defn evaluate_one_max(genomes) do
    Nx.sum(genomes, axes: [1])
  end
end

algorithm =
  Meow.objective(&Problem.evaluate_one_max/1)
  |> Meow.add_pipeline(
    MeowNx.Ops.init_binary_random_uniform(100, Problem.size()),
    Meow.pipeline([
      MeowNx.Ops.selection_tournament(1.0),
      MeowNx.Ops.crossover_uniform(0.5),
      MeowNx.Ops.mutation_bit_flip(0.001),
      MeowNx.Ops.log_best_individual(),
      Meow.Ops.max_generations(100)
    ])
  )

report = Meow.run(algorithm)

report |> Meow.Report.format_summary() |> IO.puts()
