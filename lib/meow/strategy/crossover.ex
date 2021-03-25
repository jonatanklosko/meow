defmodule Meow.Strategy.Crossover do
  @moduledoc """
  Provides a number of well known crossover strategies.

  Note that the functions assume a more specific genome
  representation (e.g. a list), so make sure their `@spec`
  is compatible with your representation of choice.
  """

  @doc """
  Implements uniform crossover.

  Given two lists representing genomes, swaps the corresponding
  genes according to the given probability.
  """
  @spec uniform(List.t(), List.t()) :: {List.t(), List.t()}
  def uniform(genome1, genome2, probability \\ 0.5) do
    genome1
    |> Enum.zip(genome2)
    |> Enum.map(fn {gene1, gene2} ->
      if :rand.uniform() < probability do
        {gene1, gene2}
      else
        {gene2, gene1}
      end
    end)
    |> Enum.unzip()
  end
end
