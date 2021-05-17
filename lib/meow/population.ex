defmodule Meow.Population do
  @moduledoc """
  Represents a group of individuals that evolve over time.

  This struct can be thought of as evolution snapshot at specific
  point in time. It contains the list of currently living individuals
  as well as information about the evolution progress.
  """

  defstruct [:genomes, :fitness, :representation_spec, generation: 1, terminated: false]

  @type t :: %__MODULE__{
          genomes: genomes(),
          fitness: fitness(),
          representation_spec: module(),
          generation: non_neg_integer(),
          terminated: boolean()
        }

  @typedoc """
  The underlying representation of the population.

  This should be a group of genomes, each encoding
  an individual (solution). There is no constraint
  on the actual type, so this could be a list,
  a tensor, or even an arbitrary binary.

  Keep in mind that depending on the representation
  chosen, you will need to use suitable evolutionary
  operations that work on the given type.
  """
  @type genomes :: any()

  @typedoc """
  The underlying representation of population's fitness.

  This represents a group of fitness values,
  each corresponding to one individual in the population.
  Similarly to `genomes` the actual type is not enforced,
  as long as it is compatible with the operations used.
  """
  @type fitness :: any()

  @doc """
  Initializes a population from genomes representation.
  """
  @spec new(genomes(), module()) :: t()
  def new(genomes, representation_spec) do
    %__MODULE__{
      genomes: genomes,
      generation: 1,
      representation_spec: representation_spec
    }
  end

  @doc """
  Calculates population size based on the underlying representation.
  """
  @spec size(t()) :: non_neg_integer()
  def size(population) do
    population.representation_spec.population_size(population.genomes)
  end

  @doc """
  Returns a list of size `times` where every item is `population`.
  """
  @spec duplicate(t(), pos_integer()) :: list(t())
  def duplicate(population, times) do
    for _ <- 1..times, do: population
  end

  @doc """
  Concatenats the given populations into a single population.

  The resulting population includes genomes from all the populations
  and is composed using `representation_spec` of the first population.
  """
  @spec concatenate(list(t())) :: t()
  def concatenate(populations) do
    representation_spec = same_representation_spec!(populations)

    join_with(
      populations,
      &representation_spec.concatenate_genomes/1,
      &representation_spec.concatenate_fitness/1
    )
  end

  @doc """
  Shortcut for `join_with/3` when the same join function
  applies for both genomes and fitness.
  """
  @spec join_with(list(t()), (genomes() | fitness() -> t())) :: t()
  def join_with(populations, join_fun) do
    join_with(populations, join_fun, join_fun)
  end

  @doc """
  Joins the given populations into a single population.

  Uses `genomes_join_fun` and `fitness_join_fun` to join
  genomes and fitness representations respectively.
  """
  @spec join_with(list(t()), (genomes() -> t()), (fitness() -> t())) :: t()
  def join_with(populations, genomes_join_fun, fitness_join_fun) do
    %__MODULE__{
      genomes: populations |> Enum.map(& &1.genomes) |> genomes_join_fun.(),
      fitness: populations |> Enum.map(& &1.fitness) |> join_fitness(fitness_join_fun),
      terminated: populations |> Enum.any?(& &1.terminated),
      generation: populations |> Enum.map(& &1.generation) |> Enum.max(),
      representation_spec: same_representation_spec!(populations)
    }
  end

  defp join_fitness(fitness_list, join_fun) do
    if Enum.any?(fitness_list, &is_nil/1) do
      nil
    else
      join_fun.(fitness_list)
    end
  end

  defp same_representation_spec!(populations) do
    populations
    |> Enum.map(& &1.representation_spec)
    |> Enum.uniq()
    |> case do
      [representation_spec] ->
        representation_spec

      _ ->
        raise ArgumentError,
              "the given populations have different representation spec, so they are not of compatible type"
    end
  end
end
