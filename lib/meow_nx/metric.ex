defmodule MeowNx.Metric do
  @moduledoc """
  Numerical implementations of basic metrics.
  """

  import Nx.Defn

  @doc """
  Finds the best individual and their fitness.
  """
  defn best_individual(genomes, fitness) do
    best_idx = Nx.argmax(fitness)
    {genomes[best_idx], fitness[best_idx]}
  end

  @doc """
  Calculates mean fitness value.
  """
  defn fitness_mean(_genomes, fitness) do
    Nx.mean(fitness)
  end

  @doc """
  Finds maximum fitness value.
  """
  defn fitness_max(_genomes, fitness) do
    Nx.reduce_max(fitness)
  end

  @doc """
  Finds minimum fitness value.
  """
  defn fitness_min(_genomes, fitness) do
    Nx.reduce_min(fitness)
  end

  @doc """
  Calculates fitness standard deviation.

  Uses the population variant of standard deviation.
  """
  defn fitness_sd(_genomes, fitness) do
    MeowNx.Utils.sd(fitness)
  end

  @doc """
  Calculates fitness entropy.

  Gives a sense of diversity in fitness values. When all
  values are the same the entropy is equal to 0, the more
  the values differ, the higher the entropy.

  By default values are grouped by their exact values, but
  when working in continous space you likely want to treat
  values as equal if they are close enough. To do that you
  can specify the `:precision` option.

  ## Options

    * `:precision` - the length of intervals to divide the
      space into. Values in the same interval will be considered
      equal. By default exact values are compared
  """
  defn fitness_entropy(_genomes, fitness, opts \\ []) do
    opts = keyword!(opts, [:precision])

    values =
      transform({fitness, opts[:precision]}, fn
        {fitness, nil} -> fitness
        {fitness, precision} -> fitness |> Nx.divide(precision) |> Nx.round()
      end)

    MeowNx.Utils.entropy(values)
  end

  @doc """
  Calculates the mean Euclidean distance between each pair
  of genomes.
  """
  defn genomes_mean_euclidean_distance(genomes, _fitness) do
    {n, _} = Nx.shape(genomes)

    sum =
      genomes
      |> MeowNx.Utils.pairwise_squared_distance()
      |> Nx.sqrt()
      |> Nx.sum()

    # Ignore diagonal elements
    sum / (n * n - n)
  end
end
