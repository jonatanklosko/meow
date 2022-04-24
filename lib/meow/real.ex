defmodule Meow.Real do
  import Nx.Defn

  import Meow.Utils

  @doc """
  Generates populations, where each genome is represented by a series
  of real numbers.

  ## Options

    * `:length` - the length of a single genome. Required

    * `:pop_size` - the number of individuals in a single population.
      Required

    * `:pop_count` - the number of populations. Defaults to `1`

    * `:min` - the minimum possible value of a gene. Defaults to `0`

    * `:max` - the maximum possible value of a gene. Defaults to `1`

  """
  defn init_random(opts \\ []) do
    opts = keyword!(opts, [:length, :pop_size, pop_count: 1, min: 0, max: 1])

    [pop_count, pop_size, length, min, max] =
      fetch_opts!(opts, [:pop_count, :pop_size, :length, :min, :max])

    Nx.random_uniform({pop_count, pop_size, length}, min, max, type: {:f, 64})
  end

  @doc """
  Performs simple uniform replacement mutation.

  Replaces every mutated gene with a random value drawn uniformly
  from the given range.

  Every gene has the same chance of mutation, configured with
  `probability`.

  ## Options

    * `:probability` - the probability of each gene getting mutated.
      Required

    * `:min` - the minimum possible value of a gene. Defaults to `0`

    * `:max` - the maximum possible value of a gene. Defaults to `1`

  """
  defn mutation_replace_uniform(genomes, opts \\ []) do
    opts = keyword!(opts, [:probability, :min, :max])
    [probability, min, max] = fetch_opts!(opts, [:probability, :min, :max])

    # Mutate each gene separately with the given probability
    mutate? = Nx.random_uniform(genomes) |> Nx.less(probability)
    mutated = Nx.random_uniform(genomes, min, max, type: Nx.type(genomes))
    Nx.select(mutate?, mutated, genomes)
  end

  @doc """
  Performs Gaussian shift mutation.

  Adds a random value to every mutated gene. The value is drawn from
  a normal distribution with mean 0 and the specified standard
  deviation.

  Every gene has the same chance of mutation, configured with
  `probability`.

  ## Options

    * `:probability` - the probability of each gene getting mutated.
      Required

    * `:sigma` - standard deviation of the normal distribution used
      for mutation. Defaults to `1`

  ## References

    * [Adaptive Mutation Strategies for Evolutionary Algorithms](https://www.dynardo.de/fileadmin/Material_Dynardo/WOST/Paper/wost2.0/AdaptiveMutation.pdf), Section 3.1

  """
  defn mutation_shift_gaussian(genomes, opts \\ []) do
    opts = keyword!(opts, [:probability, sigma: 1.0])
    [probability, sigma] = fetch_opts!(opts, [:probability, :sigma])

    # Mutate each gene separately with the given probability
    mutate? = Nx.random_uniform(genomes) |> Nx.less(probability)
    mutated = genomes + Nx.random_normal(genomes, 0.0, sigma)
    Nx.select(mutate?, mutated, genomes)
  end

  @doc """
  Performs blend-alpha crossover, also referred to as BLX-alpha.

  For parent genomes $x$ and $y$, a new offspring is produced by
  uniformly drawing new genes $z_i$ from the range
  $[x_i - \\alpha (y_i - x_i), y_i + \\alpha (y_i - x_i)]$, assuming
  $x_i < y_i$

  In other words each of the new genes $z_i$ is either in the range
  $[x_i, y_i]$ or slightly outside of that range, depending on the
  parameter alpha.

  Similarly to other crossover operations, this one also produces two
  offsprings for every pair of parents. Moreover, these offspring are
  symmetric, in the sense that the mean value of their genomes (the
  mean genome) is the same as the mean value of the parent ganomes.

  ## Options

    * `:alpha` - parameter controlling how far new genes may fall
      outside of the parent genes range. Low values emphasise
      exploitation, while high values allow for exploration. Alpha of
      0 is known as flat crossover, where new genes are drawn from
      the range `[x_i, y_i]`. Alpha of 0.5 provides a balance between
      exploration and exploitation. Defaults to `0.5`

  ## References

    * [Tackling Real-Coded Genetic Algorithms: Operators and Tools for Behavioural Analysis](https://sci2s.ugr.es/sites/default/files/files/ScientificImpact/AIRE12-1998.PDF), Section 4.3
    * [Multiobjective Evolutionary Algorithms forElectric Power Dispatch Problem](https://www.researchgate.net/figure/Blend-crossover-operator-BLX_fig1_226044085), Fig. 1.

  """
  defn crossover_blend_alpha(genomes, opts \\ []) do
    opts = keyword!(opts, alpha: 0.5)
    [alpha] = fetch_opts!(opts, [:alpha])

    {pop_count, pop_size, length} = Nx.shape(genomes)
    half_pop_size = transform(pop_size, &div(&1, 2))

    {x, y} = {genomes, swap_pairs_along_axis(genomes, axis: 1)}

    # This may look differently from the presented formula,
    # but is in fact equivalent. Also the distance y - x
    # may be negative (for y < x), but then we shift from x
    # in the opposite direction, so it works as expected.

    u = Nx.random_uniform({pop_count, half_pop_size, length})
    gamma = (1 + 2 * alpha) * u - alpha
    gamma = duplicate_along_axis(gamma, axis: 1)

    x + gamma * (y - x)
  end

  @doc """
  Performs simulated binary crossover, also referred to as SBX.

  This operation is a real representation counterpart of the single-point
  crossover applied to binary representation (hence the name). It was
  designed such that it provides the same characteristics, see the
  referenced papers for more details.

  ## Options

    * `:eta` - parameter controlling how similar offsprings are to
      the parents. Higher values imply closer resemblance, lower
      values imply more significant difference. Required

  ## References

    * [Self-Adaptive Genetic Algorithms with Simulated Binary Crossover](https://eldorado.tu-dortmund.de/bitstream/2003/5370/1/ci61.pdf)
    * [Engineering Analysis and Design Using Genetic Algorithms / Lecture 4: Real-Coded Genetic Algorithms](https://engineering.purdue.edu/~sudhoff/ee630/Lecture04.pdf)

  """
  defn crossover_simulated_binary(genomes, opts \\ []) do
    opts = keyword!(opts, [:eta])
    [eta] = fetch_opts!(opts, [:eta])

    {pop_count, pop_size, length} = Nx.shape(genomes)
    half_pop_size = transform(pop_size, &div(&1, 2))

    {x, y} = {genomes, swap_pairs_along_axis(genomes, axis: 1)}

    u = Nx.random_uniform({pop_count, half_pop_size, length})
    beta_base = Nx.select(u < 0.5, 2 * u, 1 / (2 * (1 - u)))

    beta = Nx.power(beta_base, 1 / (eta + 1))
    beta = duplicate_along_axis(beta, axis: 1)

    0.5 * ((1 + beta) * x + (1 - beta) * y)
  end
end
