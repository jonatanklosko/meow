defmodule Meow.Population do
  @moduledoc """
  Represents a group of individuals that evolve over time.

  This struct can be thought of as evolution snapshot at specific
  point in time. It contains the list of currently living individuals
  as well as information about the evolution progress.
  """

  defstruct [:genomes, :fitness, generation: 0, terminated: false]

  @type t :: %__MODULE__{
          genomes: genomes(),
          fitness: fitness(),
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
  Returns a list of size `times` where every item is `population`.
  """
  @spec duplicate(t(), pos_integer()) :: list(t())
  def duplicate(population, times) do
    for _ <- 1..times, do: population
  end

  @doc """
  Shortcut for `merge_with/3` when the same merge function
  applies for both genomes and fitness.
  """
  @spec merge_with(list(t()), (genomes() | fitness() -> t())) :: t()
  def merge_with(populations, merge_fun) do
    merge_with(populations, merge_fun, merge_fun)
  end

  @doc """
  Merges the given populations into a single population.

  Uses `genomes_merge_fun` and `fitness_merge_fun` to merge
  genomes and fitness representations respectively.
  """
  @spec merge_with(list(t()), (genomes() -> t()), (fitness() -> t())) :: t()
  def merge_with(populations, genomes_merge_fun, fitness_merge_fun) do
    %__MODULE__{
      genomes: populations |> Enum.map(& &1.genomes) |> genomes_merge_fun.(),
      fitness: populations |> Enum.map(& &1.fitness) |> merge_fitness(fitness_merge_fun),
      terminated: populations |> Enum.any?(& &1.terminated),
      generation: populations |> Enum.map(& &1.generation) |> Enum.max()
    }
  end

  defp merge_fitness(fitness_list, merge_fun) do
    if Enum.any?(fitness_list, &is_nil/1) do
      nil
    else
      merge_fun.(fitness_list)
    end
  end
end
