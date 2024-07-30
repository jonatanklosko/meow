defmodule MeowNx.Init do
  @moduledoc """
  Numerical implementations of common initializations.

  Initialization refers to the operation of generating
  a population of individuals, generally in a random way.
  """

  import Nx.Defn

  @doc """
  Generates a population, where each genome is represented
  by a series of real numbers.

  ## Options

    * `:n` - the number of individuals to generate. Required.

    * `:length` - the length of a single genome. Required.

    * `:min` - the minimum possible value of a gene. Required.

    * `:max` - the maximum possible value of a gene. Required.
  """
  defn real_random_uniform(prng_key, opts \\ []) do
    opts = keyword!(opts, [:n, :length, :min, :max])
    n = opts[:n]
    length = opts[:length]
    min = opts[:min]
    max = opts[:max]

    {random, _prng_key} =
      Nx.Random.uniform(prng_key, min, max, shape: {n, length}, type: {:f, 64})

    random
  end

  @doc """
  Generates a population, where each genome is a series of
  zeros and ones, or in other words a binary string.

  ## Options

    * `:n` - the number of individuals to generate. Required.

    * `:length` - the length of a single genome. Required.
  """
  defn binary_random_uniform(prng_key, opts \\ []) do
    opts = keyword!(opts, [:n, :length])
    n = opts[:n]
    length = opts[:length]

    {random, _prng_key} = Nx.Random.uniform(prng_key, 0, 2, shape: {n, length})
    Nx.as_type(random, {:u, 8})
  end
end
