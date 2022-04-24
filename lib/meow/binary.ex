defmodule Meow.Binary do
  import Nx.Defn

  import Meow.Utils

  @doc """
  Generates populations, where every genome is a binary string (that
  is, a series of zeroes and onces).

  ## Options

    * `:length` - the length of a single genome. Required

    * `:pop_size` - the number of individuals in a single population.
      Required

    * `:pop_count` - the number of populations. Defaults to `1`

  """
  defn init_random(opts \\ []) do
    opts = keyword!(opts, [:length, :pop_size, pop_count: 1])
    [pop_count, pop_size, length] = fetch_opts!(opts, [:pop_count, :pop_size, :length])
    Nx.random_uniform({pop_count, pop_size, length}, 0, 2) |> Nx.as_type({:u, 8})
  end

  @doc """
  Performs bit-flip mutation.

  ## Options

    * `:probability` - the probability of each gene getting mutated.
      Required

  """
  defn mutation_bit_flip(genomes, opts \\ []) do
    opts = keyword!(opts, [:probability])
    [probability] = fetch_opts!(opts, [:probability])

    # Mutate each gene separately with the given probability
    mutate? = Nx.random_uniform(genomes) |> Nx.less(probability)
    mutated = Nx.subtract(1, genomes)
    Nx.select(mutate?, mutated, genomes)
  end
end
