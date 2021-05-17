defmodule Meow.RepresentationSpec do
  @moduledoc """
  Defines a few basic operations for on a population representation.

  Some core modules need to know how to perform certain
  operations on genomes and those operations are representation
  dependent, hence such specification needs to be provided.
  """

  alias Meow.Population

  @doc """
  Extracts population size from the given genomes representation.
  """
  @callback population_size(Population.genomes()) :: non_neg_integer()

  @doc """
  Concatenates genomes of multiple groups of individuals.
  """
  @callback concatenate_genomes(list(Population.genomes())) :: Population.genomes()

  @doc """
  Concatenates fitnesses of multiple groups of individuals.

  The order of individuals should match the one from `concatenate_genomes/1`.
  """
  @callback concatenate_fitness(list(Population.fitness())) :: Population.fitness()
end
