defmodule Meow.Topology do
  @moduledoc """
  A number of topology functions used in multi-population algorithms.

  Topology defines communication scheme for multiple populations
  and is essentially a directed graph, where every population
  points to its direct neighbours.
  """

  @typedoc """
  A topology function encodes a topology graph.

  Given the number of populations and the index of a specific
  population, topology function returns the list of neighbours
  for this population.

  Representing the topology via function has the benefit of being
  population size agnostic.
  """
  @type topology_fun ::
          (number_of_populations(), population_index() -> neighbour_population_indices())

  @type number_of_populations :: pos_integer()
  @type population_index :: non_neg_integer()
  @type neighbour_population_indices :: list(population_index())

  @doc """
  Represents unidirectional ring topology.
  """
  @spec ring(number_of_populations(), population_index()) :: neighbour_population_indices()
  def ring(n, idx) do
    next_idx = (idx + 1) |> rem(n)
    [next_idx]
  end
end
