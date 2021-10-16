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
end
