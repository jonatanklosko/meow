defmodule MeowNx.Crossover do
  @moduledoc """
  Numerical implementations of common crossover operations.

  Crossover is a genetic operation that combines the genetic
  information of parents to generate offspring.
  It serves as a primary way of generating new solutions
  in an evolutionary algorithm.

  Most of the operations group parents into pairs and produce
  a corresponding pair of offsprings.
  """

  import Nx.Defn

  alias MeowNx.Utils

  # Implementation note
  #
  # Since most operations produce two offsprings,
  # we need to consider every pair of parents twice.
  # Generally we designate the original genomes tensor as x
  # and the genomes tensor with swapped adjacent rows as y.
  # Consequently parent rows (a, b) in tensor x correspond
  # to rows (b, a) in tensor y, which means we perform all
  # operations on every pair of parents twice.

  @doc """
  Performs uniform crossover.

  For parent genomes $x$ and $y$, this operation swaps genes
  $x_i$ and $y_i$ according to the given probability.

  ## Options

    * `:probability` - the probability of corresponding parent
      genes being swapped. Defaults to `0.5`

  ## References

    * [On the Virtues of Parameterized Uniform Crossover](http://www.mli.gmu.edu/papers/91-95/91-18.pdf)
  """
  defn uniform(parents, opts \\ []) do
    opts = keyword!(opts, probability: 0.5)
    probability = opts[:probability]

    {n, length} = Nx.shape(parents)
    half_n = transform(n, &div(&1, 2))

    swapped_parents = Utils.swap_adjacent_rows(parents)

    swap? =
      Nx.random_uniform({half_n, length})
      |> Nx.less_equal(probability)
      |> Utils.duplicate_rows()

    Nx.select(swap?, swapped_parents, parents)
  end

  @doc """
  Performs single-point crossover.

  For parent genomes $x$ and $y$, this operation chooses
  a random split point and swaps all genes $x_i$, $y_i$
  on one side of that split point.
  """
  defn single_point(parents) do
    {n, length} = Nx.shape(parents)
    half_n = transform(n, &div(&1, 2))

    swapped_parents = Utils.swap_adjacent_rows(parents)

    # Generate n / 2 split points (like [5, 2, 3]), and replicate
    # them for adjacent parents (like [5, 5, 2, 2, 3, 3])
    split_idx =
      Nx.random_uniform({half_n, 1}, 1, length - 1)
      |> Utils.duplicate_rows()

    swap? = Nx.iota({1, length}) |> Nx.less_equal(split_idx)

    Nx.select(swap?, swapped_parents, parents)
  end

  @doc """
  Performs blend-alpha crossover, also referred to as BLX-alpha.

  For parent genomes $x$ and $y$, a new offspring is produced
  by uniformly drawing new genes $z_i$ from the range
  $[x_i - \\alpha (y_i - x_i), y_i + \\alpha (y_i - x_i)]$, assuming $x_i < y_i$

  In other words each of the new genes $z_i$ is either in
  the range $[x_i, y_i]$ or slightly outside of that range,
  depending on the parameter alpha.

  Similarly to other crossover operations, this one also produces
  two offsprings for every pair of parents.
  Moreover, these offspring are symmetric, in the sense
  that the mean value of their genomes (i.e. the mean genome)
  is the same as the mean value of the parent ganomes.

  ## Options

    * `:alpha` - parameter controlling how far new genes
      may fall outside of the parent genes range.
      Low values emphasise exploitation, while high values
      allow for exploration. Alpha of 0 is known as flat crossover,
      where new genes are drawn from the range `[x_i, y_i]`.
      Alpha of 0.5 provides a balance between exploration and exploitation.
      Defaults to `0.5`.

  ## References

    * [Tackling Real-Coded Genetic Algorithms: Operators and Tools for Behavioural Analysis](https://sci2s.ugr.es/sites/default/files/files/ScientificImpact/AIRE12-1998.PDF), Section 4.3
    * [Multiobjective Evolutionary Algorithms forElectric Power Dispatch Problem](https://www.researchgate.net/figure/Blend-crossover-operator-BLX_fig1_226044085), Fig. 1.
  """
  defn blend_alpha(parents, opts \\ []) do
    opts = keyword!(opts, alpha: 0.5)
    alpha = opts[:alpha]

    {n, length} = Nx.shape(parents)
    half_n = transform(n, &div(&1, 2))

    {x, y} = {parents, Utils.swap_adjacent_rows(parents)}

    # This may look differently from the presented formula,
    # but is in fact equivalent. Also the distance y - x
    # may be negative (for y < x), but then we shift from x
    # in the opposite direction, so it works as expected.

    gamma = (1 + 2 * alpha) * Nx.random_uniform({half_n, length}) - alpha
    gamma = Utils.duplicate_rows(gamma)

    x + gamma * (y - x)
  end

  @doc """
  Performs simulated binary crossover, also referred to as SBX.

  This operation is a real representation counterpart of the single-point
  crossover applied to binary representation (hence the name).
  It was designed such that it provides the same characteristics,
  see the referenced papers for more details.

  ## Options

    * `:eta` - parameter controlling how similar offsprings
      are to the parents. Higher values imply closer resemblance,
      lower values imply more significant difference. Required.

  ## References

    * [Self-Adaptive Genetic Algorithms with Simulated Binary Crossover](https://eldorado.tu-dortmund.de/bitstream/2003/5370/1/ci61.pdf)
    * [Engineering Analysis and Design Using Genetic Algorithms / Lecture 4: Real-Coded Genetic Algorithms](https://engineering.purdue.edu/~sudhoff/ee630/Lecture04.pdf)
  """
  defn simulated_binary(parents, opts \\ []) do
    opts = keyword!(opts, [:eta])
    eta = opts[:eta]

    {n, length} = Nx.shape(parents)
    half_n = transform(n, &div(&1, 2))

    {x, y} = {parents, Utils.swap_adjacent_rows(parents)}

    beta_base =
      Nx.random_uniform({half_n, length})
      |> Nx.map(fn u ->
        if Nx.less(u, 0.5) do
          2 * u
        else
          1 / (2 * (1 - u))
        end
      end)

    beta = Nx.power(beta_base, 1 / (eta + 1))
    beta = Utils.duplicate_rows(beta)

    0.5 * ((1 + beta) * x + (1 - beta) * y)
  end
end
