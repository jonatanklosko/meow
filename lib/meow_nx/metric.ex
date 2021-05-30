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
end
