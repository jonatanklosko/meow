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
    # TODO: support percentage, something like {:fraction, 0.2}
    opts = keyword!(opts, [:n])
    result_n = opts[:n]

    fitness_cumulative = MeowNx.Utils.cumulative_sum(fitness)
    fitness_sum = fitness_cumulative[-1]

    # Random points on the cumulative ruler
    points = Nx.random_uniform({result_n, 1}, 0, fitness_sum)
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
    # TODO: support percentage, something like {:fraction, 0.2}
    opts = keyword!(opts, [:n])
    result_n = opts[:n]

    fitness_cumulative = MeowNx.Utils.cumulative_sum(fitness)
    fitness_sum = fitness_cumulative[-1]

    # Random points on the cumulative ruler, each in its own interval
    step = Nx.divide(fitness_sum, result_n)
    start = Nx.random_uniform({}, 0, step)
    points = Nx.iota({result_n, 1}) |> Nx.multiply(step) |> Nx.add(start)
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
