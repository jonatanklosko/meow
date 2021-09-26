defmodule Meow.TestRepresentationSpec do
  @moduledoc false

  @behaviour Meow.RepresentationSpec

  @impl true
  def population_size(genomes), do: length(genomes)

  @impl true
  def concatenate_genomes(genomes_list), do: Enum.concat(genomes_list)

  @impl true
  def concatenate_fitness(fitness_list), do: Enum.concat(fitness_list)
end
