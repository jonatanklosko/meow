defmodule MeowNx.RepresentationSpec do
  @moduledoc """
  Specification of population tensor representation.
  """

  @behaviour Meow.RepresentationSpec

  import Nx.Defn

  @impl true
  def population_size(genomes) do
    genomes |> Nx.shape() |> elem(0)
  end

  @impl true
  def concatenate_genomes(genomes_list) do
    genomes_list
    |> List.to_tuple()
    |> concatenate_tuple()
  end

  @impl true
  def concatenate_fitness(fitness_list) do
    fitness_list
    |> List.to_tuple()
    |> concatenate_tuple()
  end

  @impl true
  def encode_genomes(genomes) do
    # Ensure we have access to the data rather than
    # a device reference
    Nx.backend_transfer(genomes)
  end

  @impl true
  def decode_genomes(genomes) do
    genomes
  end

  defn concatenate_tuple(populations) do
    populations
    |> transform(&Tuple.to_list/1)
    |> Nx.concatenate()
  end
end
