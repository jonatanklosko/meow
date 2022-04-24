defmodule Meow.Common do
  import Nx.Defn

  import Meow.Utils

  @doc """
  Performs tournament selection with tournament size of 2.

  Returns a `{genomes, fitness}` tuple with the selected individuals.

  Randomly creates `n` groups of individuals (2 per group) and picks
  the best individual from each group according to fitness.

  ## Options

    * `:n` - the number of individuals to select per population. Required

  """
  defn selection_tournament(genomes, fitness, opts \\ []) do
    opts = keyword!(opts, [:n])
    [n] = fetch_opts!(opts, [:n])

    {pop_count, pop_size, length} = Nx.shape(genomes)

    idx1 = Nx.random_uniform({pop_count, n}, 0, pop_size, type: {:u, 32})
    idx2 = Nx.random_uniform({pop_count, n}, 0, pop_size, type: {:u, 32})

    genomes1 = batched_take(genomes, idx1)
    fitness1 = batched_take(fitness, idx1)

    genomes2 = batched_take(genomes, idx2)
    fitness2 = batched_take(fitness, idx2)

    wins? = Nx.greater(fitness1, fitness2)
    winning_fitness = Nx.select(wins?, fitness1, fitness2)

    winning_genomes =
      wins?
      |> Nx.new_axis(-1)
      |> Nx.broadcast({pop_count, n, length})
      |> Nx.select(genomes1, genomes2)

    {winning_genomes, winning_fitness}
  end

  @doc """
  Performs natural selection.

  Returns a `{genomes, fitness}` tuple with the selected individuals.

  Sorts individuals according to fitness and picks the `n` fittest.

  ## Options

    * `:n` - the number of individuals to select. Must not exceed
      population size. Required

  """
  defn selection_natural(genomes, fitness, opts \\ []) do
    opts = keyword!(opts, [:n])
    # TODO: handle n > pop_size, either throw or wrap
    [n] = fetch_opts!(opts, [:n])

    sort_idx = Nx.argsort(fitness, axis: 1, direction: :desc)
    top_idx = Nx.slice_along_axis(sort_idx, 0, n, axis: 1)

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

    * `:n` - the number of individuals to select per population. Required

  ## References

    * [Fitness proportionate selection](https://en.wikipedia.org/wiki/Fitness_proportionate_selection)

  """
  defn selection_roulette(genomes, fitness, opts \\ []) do
    opts = keyword!(opts, [:n])
    [n] = fetch_opts!(opts, [:n])

    {pop_count, _pop_size, _length} = Nx.shape(genomes)

    fitness_cumulative = cumulative_sum(fitness, axis: 1)
    fitness_sum = fitness_cumulative[[0..-1//1, -1]]

    # Random points on the cumulative ruler
    points = Nx.random_uniform({pop_count, n}, 0.0, 1.0) * Nx.reshape(fitness_sum, {pop_count, 1})
    idx = cumulative_points_to_indices(fitness_cumulative, points)

    take_individuals(genomes, fitness, idx)
  end

  @doc """
  Performs stochastic universal sampling.

  Essentially an unbiased version of `roulette/3`.

  Technically, this approach devides the fitness "cumulative ruler"
  into evenly spaced intervals and uses a single random value to pick
  one individual per interval.

  ## Options

    * `:n` - the number of individuals to select per population. Required

  ## References

    * [Stochastic universal sampling](https://en.wikipedia.org/wiki/Stochastic_universal_sampling)

  """
  defn slection_stochastic_universal_sampling(genomes, fitness, opts \\ []) do
    opts = keyword!(opts, [:n])
    [n] = fetch_opts!(opts, [:n])

    {pop_count, _pop_size, _length} = Nx.shape(genomes)

    fitness_cumulative = cumulative_sum(fitness, axis: 1)
    fitness_sum = fitness_cumulative[[0..-1//1, -1]]

    # Random points on the cumulative ruler, each in its own interval
    step = Nx.divide(fitness_sum, n)
    start = Nx.random_uniform({pop_count}, 0.0, 1.0) * step

    points = Nx.iota({pop_count, n}, axis: 1) * Nx.new_axis(step, -1) + Nx.new_axis(start, -1)
    idx = cumulative_points_to_indices(fitness_cumulative, points)

    take_individuals(genomes, fitness, idx)
  end

  # Converts points on a "cumulative ruler" to indices
  defnp cumulative_points_to_indices(fitness_cumulative, points) do
    points
    |> Nx.new_axis(-1)
    |> Nx.less(Nx.new_axis(fitness_cumulative, -2))
    |> Nx.argmax(axis: -1)
  end

  defnp take_individuals(genomes, fitness, idx) do
    {batched_take(genomes, idx), batched_take(fitness, idx)}
  end

  @doc """
  Performs uniform crossover.

  For parent genomes $x$ and $y$, this operation swaps genes $x_i$
  and $y_i$ according to the given probability.

  ## Options

    * `:probability` - the probability of corresponding parent genes
      being swapped. Defaults to `0.5`

  ## References

    * [On the Virtues of Parameterized Uniform Crossover](http://www.mli.gmu.edu/papers/91-95/91-18.pdf)

  """
  defn crossover_uniform(genomes, opts \\ []) do
    opts = keyword!(opts, probability: 0.5)
    [probability] = fetch_opts!(opts, [:probability])

    {pop_count, pop_size, length} = Nx.shape(genomes)
    half_pop_size = transform(pop_size, &div(&1, 2))

    swapped_genomes = swap_pairs_along_axis(genomes, axis: 1)

    swap? =
      Nx.random_uniform({pop_count, half_pop_size, length})
      |> Nx.less_equal(probability)
      |> duplicate_along_axis(axis: 1)

    Nx.select(swap?, swapped_genomes, genomes)
  end

  @doc """
  Performs single-point crossover.

  For parent genomes $x$ and $y$, this operation chooses a random
  split point and swaps all genes $x_i$, $y_i$ on one side of that
  split point.
  """
  defn crossover_single_point(genomes) do
    {pop_count, pop_size, length} = Nx.shape(genomes)
    half_pop_size = transform(pop_size, &div(&1, 2))

    swapped_genomes = swap_pairs_along_axis(genomes, axis: 1)

    split_idx =
      Nx.random_uniform({pop_count, half_pop_size, 1}, 1, length)
      |> duplicate_along_axis(axis: 1)

    swap? = split_idx <= Nx.iota({1, 1, length})

    Nx.select(swap?, swapped_genomes, genomes)
  end

  @doc """
  Performs multi-point crossover.

  A generalized version of `single_point/1` crossover that splits a
  pair of genomes in multiple random points and swaps every second
  chunk.

  ## Options

    * `:points` - the number of crossover points

  """
  defn crossover_multi_point(genomes, opts \\ []) do
    opts = keyword!(opts, [:points])
    [points] = fetch_opts!(opts, [:points])

    {pop_count, pop_size, length} = Nx.shape(genomes)
    half_pop_size = transform(pop_size, &div(&1, 2))

    transform({length, points}, fn {length, points} ->
      unless Elixir.Kernel.<(points, length) do
        raise ArgumentError,
              "#{points}-point crossover is not valid for genome of length #{length}"
      end
    end)

    swapped_genomes = swap_pairs_along_axis(genomes, axis: 1)

    # For each pair of parents we generate k unique crossover points,
    # then we convert each of them to 1-point crossover mask and finally
    # combine these masks using gen-wise XOR (sum modulo 2)

    split_idx =
      random_idx_without_replacement(
        shape: {pop_count, half_pop_size, points, 1},
        min: 1,
        max: length,
        axis: 2
      )

    swap? =
      Nx.less_equal(split_idx, Nx.iota({1, 1, 1, length}))
      |> Nx.sum(axes: [2])
      |> Nx.remainder(2)
      |> duplicate_along_axis(axis: 1)

    Nx.select(swap?, swapped_genomes, genomes)
  end
end
