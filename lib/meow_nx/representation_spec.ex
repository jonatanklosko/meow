defmodule MeowNx.RepresentationSpec do
  @moduledoc """
  Specification of population tensor representation.
  """

  @behaviour Meow.RepresentationSpec

  @impl true
  def population_size(genomes) do
    genomes |> Nx.shape() |> elem(0)
  end

  @impl true
  def concatenate_genomes(genomes_list) do
    Nx.concatenate(genomes_list)
  end

  @impl true
  def concatenate_fitness(fitness_list) do
    Nx.concatenate(fitness_list)
  end
end
