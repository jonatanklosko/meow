defmodule Meow.Op do
  @enforce_keys [:name, :impl, :requires_fitness, :invalidates_fitness]

  defstruct [:name, :impl, :requires_fitness, :invalidates_fitness]

  def apply(population, operation) do
    operation.impl.(population)
  end

  # Helpers to use when building custom operations

  def map_genomes(population, fun) do
    update_in(population.genomes, fun)
  end

  def map_genomes_and_fitness(population, fun) do
    {genomes, fitness} = fun.(population.genomes, population.fitness)
    %{population | genomes: genomes, fitness: fitness}
  end
end
