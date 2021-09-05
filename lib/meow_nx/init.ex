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
  defn real_random_uniform(opts \\ []) do
    opts = keyword!(opts, [:n, :length, :min, :max])
    n = opts[:n]
    length = opts[:length]
    min = opts[:min]
    max = opts[:max]

    Nx.random_uniform({n, length}, min, max)
  end

  @doc """
  Generates a population, where each genome is a series of
  zeros and ones, or in other words a binary string.

  ## Options

    * `:n` - the number of individuals to generate. Required.

    * `:length` - the length of a single genome. Required.
  """
  defn binary_random_uniform(opts \\ []) do
    opts = keyword!(opts, [:n, :length])
    n = opts[:n]
    length = opts[:length]

    Nx.random_uniform({n, length}, 0, 2) |> Nx.as_type({:u, 8})
  end
end
