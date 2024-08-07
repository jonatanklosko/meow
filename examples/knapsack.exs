# In "0-1 knapsnack problem" the objective is to pick a subset
# of objects, such that the total weight is within limit and the
# profit is maximised.

# This example comes from https://en.wikipedia.org/wiki/Knapsack_problem
# and the highest fitness (maximal possible profit) is 1270.

# We use the binary representation, where n-th gene indicates whether
# n-th object is in the subset.

Mix.install([
  {:meow, "~> 0.1.0-dev", github: "jonatanklosko/meow"},
  {:nx, "~> 0.7.0"},
  {:exla, "~> 0.7.0"}
])

Nx.Defn.global_default_options(compiler: EXLA)

defmodule Problem do
  import Nx.Defn

  @profits Nx.tensor([505, 352, 458, 220, 345, 414, 498, 545, 473, 543])
  @object_weights Nx.tensor([23, 26, 20, 18, 32, 27, 29, 26, 30, 27])
  @weight_limit Nx.tensor(67)

  def size, do: Nx.size(@profits)

  defn evaluate_knapsack(genomes) do
    total_profit = Nx.dot(genomes, @profits)
    total_weight = Nx.dot(genomes, @object_weights)
    in_limit? = Nx.less_equal(total_weight, @weight_limit)
    Nx.select(in_limit?, total_profit, 0)
  end
end

algorithm =
  Meow.objective(&Problem.evaluate_knapsack/1)
  |> Meow.add_pipeline(
    MeowNx.Ops.init_binary_random_uniform(100, Problem.size()),
    Meow.pipeline([
      MeowNx.Ops.selection_tournament(1.0),
      MeowNx.Ops.crossover_multi_point(3),
      MeowNx.Ops.mutation_bit_flip(0.1),
      MeowNx.Ops.log_best_individual(),
      Meow.Ops.max_generations(100)
    ])
  )

report = Meow.run(algorithm)
report |> Meow.Report.format_summary() |> IO.puts()
