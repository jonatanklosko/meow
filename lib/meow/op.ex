defmodule Meow.Op do
  @enforce_keys [:name, :impl, :requires_fitness, :invalidates_fitness]

  defstruct [:name, :impl, :requires_fitness, :invalidates_fitness]

  alias Meow.Population

  @type t :: %__MODULE__{
          name: String.t(),
          impl: (Population.t() -> Population.t()),
          requires_fitness: boolean(),
          invalidates_fitness: boolean()
        }

  @doc """
  Applies `operation` to `population` and returns
  a new transformed population.
  """
  @spec apply(Population.t(), t()) :: Population.t()
  def apply(population, operation)

  def apply(%{fitness: nil}, %{requires_fitness: true}) do
    raise ArgumentError, "operation requires fitness, but it has not been computed"
  end

  def apply(population, operation) do
    operation.impl.(population)
  end

  # Helpers to use when building custom operations

  @doc """
  Updates population genomes with the given function.
  """
  @spec map_genomes(Population.t(), (Population.genomes() -> Population.genomes())) ::
          Population.t()
  def map_genomes(population, fun) do
    update_in(population.genomes, fun)
  end

  @doc """
  Updates both population genomes and fitness with the given function.
  """
  @spec map_genomes_and_fitness(
          Population.t(),
          (Population.genomes(), Population.fitness() ->
             {Population.genomes(), Population.fitness()})
        ) :: Population.t()
  def map_genomes_and_fitness(population, fun) do
    {genomes, fitness} = fun.(population.genomes, population.fitness)
    %{population | genomes: genomes, fitness: fitness}
  end
end
