defmodule Meow.Population do
  @moduledoc """
  Represents a group of individuals that evolve over time.

  This struct can be thought of as evolution snapshot at specific
  point in time. It contains the list of currently living individuals
  as well as information about the evolution progress.
  """

  defstruct [:genomes, :fitness, generation: 0, terminated: false]

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
end
