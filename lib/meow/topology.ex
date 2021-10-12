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

  @doc """
  Represents a  2-dimensional mesh topology.

  The populations are arranged into a square grid, but the grid doesn't have
  to be complete, so an arbitrary number of populations is supported.
  """
  @spec mesh2d(number_of_populations(), population_index()) :: neighbour_population_indices()
  def mesh2d(n, idx) do
    size =
      n
      |> :math.sqrt()
      |> ceil()

    row = div(idx, size)
    col = rem(idx, size)

    vertical_nieghbours =
      [row - 1, row + 1]
      |> Enum.filter(&mesh2d_in_bound?(&1, size))
      |> Enum.map(fn neighbour_row -> size * neighbour_row + col end)

    horizontal_neighbours =
      [col - 1, col + 1]
      |> Enum.filter(&mesh2d_in_bound?(&1, size))
      |> Enum.map(fn neighbour_col -> size * row + neighbour_col end)

    (vertical_nieghbours ++ horizontal_neighbours)
    |> Enum.filter(fn idx -> idx < n end)
    |> Enum.sort()
  end

  defp mesh2d_in_bound?(row_or_col_idx, size) do
    row_or_col_idx >= 0 and row_or_col_idx < size
  end
end
