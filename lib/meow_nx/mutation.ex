defmodule MeowNx.Mutation do
  @moduledoc """
  Numerical implementations of common mutation operations.

  Mutation is a genetic operation that randomly alters genetic
  information of some individuals within the population,
  usually according to a fixed probability.
  Mutation is used to maintain genetic diversity within the population
  as it steps from one generation to another. It effectively introduces
  a bit of additional randomness to the evolutionary algorithm, so that
  more diversified solutions are explored. It may also help to reduce
  too rapid convergence of the algorithm to a local minimum.
  """

  import Nx.Defn

  @doc """
  Performs simple uniform replacement mutation.

  Replaces every mutated gene with a random value drawn
  uniformly from the given range.

  Every gene has the same chance of mutation,
  configured with `probability`.

  ## Options

    * `:probability` - the probability of each gene
      getting mutated. Required.

    * `:min` - the lower bound of the range to draw from.
      Required.

    * `:min` - the upper bound of the range to draw from.
      Required.

  """
  defn replace_uniform(genomes, opts \\ []) do
    opts = keyword!(opts, [:probability, :min, :max])
    probability = opts[:probability]
    min = opts[:min]
    max = opts[:max]

    shape = Nx.shape(genomes)

    # Mutate each gene separately with the given probability
    mutate? = Nx.random_uniform(shape) |> Nx.less(probability)
    mutated = Nx.random_uniform(shape, min, max)
    Nx.select(mutate?, mutated, genomes)
  end

  @doc """
  Performs Gaussian shift mutation.

  Adds a random value to every mutated gene.
  The value is drawn from a normal distribution
  with mean 0 and the specified standard deviation.

  Every gene has the same chance of mutation,
  configured with `probability`.

  ## Options

    * `:probability` - the probability of each gene
      getting mutated. Required.

    * `:sigma` - standard deviation of the normal
      distribution used for mutation. Defaults to 1.

  ## References

    * [Adaptive Mutation Strategies for Evolutionary Algorithms](https://www.dynardo.de/fileadmin/Material_Dynardo/WOST/Paper/wost2.0/AdaptiveMutation.pdf), Section 3.1
  """
  defn shift_gaussian(genomes, opts \\ []) do
    opts = keyword!(opts, [:probability, sigma: 1])
    probability = opts[:probability]
    sigma = opts[:sigma]

    shape = Nx.shape(genomes)

    # Mutate each gene separately with the given probability
    mutate? = Nx.random_uniform(shape) |> Nx.less(probability)
    mutated = genomes + Nx.random_normal(shape, 0.0, sigma)
    Nx.select(mutate?, mutated, genomes)
  end
end
