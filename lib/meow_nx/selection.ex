defmodule MeowNx.Selection do
  @moduledoc """
  Numerical implementations of common selection operations.

  Selection is a genetic operation that picks a number
  of individuals out of a population. Oftentimes those
  individuals are then used for breeding (crossover).

  All of the selection functions require selection size `:n`,
  which can be either absolute (integer) or relative to
  population size (float). For instance, if you want to select
  80% of the population, you can simply specify the size as `0.8`.
  """

  import Nx.Defn

  require MeowNx.Utils

  @doc """
  Performs tournament selection with tournament size of 2.

  Returns a `{genomes, fitness}` tuple with the selected individuals.

  Randomly creates `n` groups of individuals (2 per group) and picks
  the best individual from each group according to fitness.

  ## Options

    * `:n` - the number of individuals to select. Required.
  """
  defn tournament(genomes, fitness, opts \\ []) do
    opts = keyword!(opts, [:n])
    n = MeowNx.Utils.resolve_n(opts[:n], genomes)

    {base_n, length} = Nx.shape(genomes)

    idx1 = Nx.random_uniform({n}, 0, base_n, type: {:u, 32})
    idx2 = Nx.random_uniform({n}, 0, base_n, type: {:u, 32})

    parents1 = Nx.take(genomes, idx1)
    fitness1 = Nx.take(fitness, idx1)

    parents2 = Nx.take(genomes, idx2)
    fitness2 = Nx.take(fitness, idx2)

    wins? = Nx.greater(fitness1, fitness2)
    winning_fitness = Nx.select(wins?, fitness1, fitness2)

    winning_genomes =
      wins?
      |> Nx.reshape({n, 1})
      |> Nx.broadcast({n, length})
      |> Nx.select(parents1, parents2)

    {winning_genomes, winning_fitness}
  end

  @doc """
  Performs natural selection.

  Returns a `{genomes, fitness}` tuple with the selected individuals.

  Sorts individuals according to fitness and picks the `n` fittest.

  ## Options

    * `:n` - the number of individuals to select. Must not exceed
      population size. Required.
  """
  defn natural(genomes, fitness, opts \\ []) do
    opts = keyword!(opts, [:n])
    n = MeowNx.Utils.resolve_n(opts[:n], genomes, limit_to_base: true)

    sort_idx = Nx.argsort(fitness, direction: :desc)
    top_idx = sort_idx[0..(n - 1)]

    take_individuals(genomes, fitness, top_idx)
  end

  @doc """
  Performs roulette selection.

  Returns a `{genomes, fitness}` tuple with the selected individuals.

  Draws a random individual `n` times, such that the probability
  of each individual being selected is proportional to their fitness.

  Keep in mind that individuals with fitness less or equal to 0
  have no chance of being selected.

  ## Options

    * `:n` - the number of individuals to select. Required.

  ## References

    * [Fitness proportionate selection](https://en.wikipedia.org/wiki/Fitness_proportionate_selection)
  """
  defn roulette_selection(genomes, fitness, opts \\ []) do
    opts = keyword!(opts, [:n])
    n = MeowNx.Utils.resolve_n(opts[:n], genomes)

    fitness_cumulative = MeowNx.Utils.cumulative_sum(fitness)
    fitness_sum = fitness_cumulative[-1]

    # Random points on the cumulative ruler
    points = Nx.random_uniform({n, 1}, 0, fitness_sum)
    idx = cumulative_points_to_indices(fitness_cumulative, points)

    take_individuals(genomes, fitness, idx)
  end

  @doc """
  Performs stochastic universal sampling.

  Essentially an unbiased version of `roulette_selection/3`.

  Technically, this approach devides the fitness "cumulative ruler"
  into evenly spaced intervals and uses a single random value to pick
  one individual per interval.

  ## Options

    * `:n` - the number of individuals to select. Required.

  ## References

    * [Stochastic universal sampling](https://en.wikipedia.org/wiki/Stochastic_universal_sampling)
  """
  defn stochastic_universal_sampling(genomes, fitness, opts \\ []) do
    opts = keyword!(opts, [:n])
    n = MeowNx.Utils.resolve_n(opts[:n], genomes)

    fitness_cumulative = MeowNx.Utils.cumulative_sum(fitness)
    fitness_sum = fitness_cumulative[-1]

    # Random points on the cumulative ruler, each in its own interval
    step = Nx.divide(fitness_sum, n)
    start = Nx.random_uniform({}, 0, step)
    points = Nx.iota({n, 1}) |> Nx.multiply(step) |> Nx.add(start)
    idx = cumulative_points_to_indices(fitness_cumulative, points)

    take_individuals(genomes, fitness, idx)
  end

  # Converts points on a "cumulative ruler" to indices
  defnp cumulative_points_to_indices(fitness_cumulative, points) do
    {n} = Nx.shape(fitness_cumulative)

    points
    |> Nx.less(Nx.reshape(fitness_cumulative, {1, n}))
    |> Nx.argmax(axis: 1)
  end

  defnp take_individuals(genomes, fitness, idx) do
    {Nx.take(genomes, idx), Nx.take(fitness, idx)}
  end
end
