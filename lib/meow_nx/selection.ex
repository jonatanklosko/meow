defmodule MeowNx.Selection do
  @moduledoc """
  Numerical implementations of common selection operations.

  Selection is a genetic operation that picks a number
  of individuals out of a population. Oftentimes those
  individuals are then used for breeding (crossover).
  """

  import Nx.Defn

  @doc """
  Performs tournament selection with tournament size of 2.

  Returns a `{genomes, fitness}` tuple with the selected individuals.

  Randomly creates `n` groups of individuals (2 per group)
  and picks the best individual from each group according to fitness.

  ## Options

    * `:n` - the number of individuals to select. Required.
  """
  defn tournament(genomes, fitness, opts \\ []) do
    # TODO: support percentage, something like {:fraction, 0.2}
    opts = keyword!(opts, [:n])
    result_n = opts[:n]

    {n, length} = Nx.shape(genomes)

    idx1 = Nx.random_uniform({result_n}, 0, n, type: {:u, 32})
    idx2 = Nx.random_uniform({result_n}, 0, n, type: {:u, 32})

    parents1 = Nx.take(genomes, idx1)
    fitness1 = Nx.take(fitness, idx1)

    parents2 = Nx.take(genomes, idx2)
    fitness2 = Nx.take(fitness, idx2)

    wins? = Nx.greater(fitness1, fitness2)
    winning_fitness = Nx.select(wins?, fitness1, fitness2)

    winning_genomes =
      wins?
      |> Nx.reshape({result_n, 1})
      |> Nx.broadcast({result_n, length})
      |> Nx.select(parents1, parents2)

    {winning_genomes, winning_fitness}
  end

  @doc """
  Performs natural selection.

  Returns a `{genomes, fitness}` tuple with the selected individuals.

  Sorts individuals according to fitness and picks the `n` fittest.

  ## Options

    * `:n` - the number of individuals to select.
      Must not exceed population size. Required.
  """
  defn natural(genomes, fitness, opts \\ []) do
    # TODO: support percentage, something like {:fraction, 0.2}
    # TODO: validate that n is not larger than population size
    result_n = opts[:n]

    sort_idx = Nx.argsort(fitness, direction: :desc)
    top_idx = sort_idx[0..(result_n - 1)]

    best_genomes = Nx.take(genomes, top_idx)
    best_fitness = Nx.take(fitness, top_idx)

    {best_genomes, best_fitness}
  end
end
