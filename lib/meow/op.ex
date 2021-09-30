defmodule Meow.Op do
  @moduledoc """
  A structure describing an evolutionary operation.

  Operation is a single step in an evolutionary pipeline
  and is responsible for transforming the population from
  one state into another state.

  The structure carries a number of operation information
  relevant to the framework, as well as an actual implementation
  of the operation.
  """

  @enforce_keys [
    :name,
    :impl,
    :requires_fitness,
    :invalidates_fitness,
    :in_representations
  ]

  defstruct [
    :name,
    :impl,
    :requires_fitness,
    :invalidates_fitness,
    :in_representations,
    out_representation: :same
  ]

  alias Meow.{Population, Op}

  @type t :: %__MODULE__{
          name: String.t(),
          impl: (Population.t(), Op.Context.t() -> Population.t()),
          requires_fitness: boolean(),
          invalidates_fitness: boolean(),
          in_representations: :any | list(Population.representation()),
          out_representation: :same | Population.representation()
        }

  @doc """
  Applies `operation` to `population` and returns
  a new transformed population.
  """
  @spec apply(Population.t(), t(), Op.Context.t()) :: Population.t()
  def apply(population, operation, ctx)

  def apply(%{fitness: nil}, %{requires_fitness: true}, _ctx) do
    raise ArgumentError, "operation requires fitness, but it has not been computed"
  end

  def apply(population, operation, ctx) do
    new_population = operation.impl.(population, ctx)

    case operation.out_representation do
      :same -> new_population
      representation -> %{new_population | representation: representation}
    end
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
