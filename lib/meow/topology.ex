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
  def ring(n, idx) when n > 1 do
    next_idx = (idx + 1) |> rem(n)
    [next_idx]
  end

  @doc """
  Represents a 2-dimensional mesh topology.

  The populations are arranged into a square grid, but the grid doesn't have
  to be complete, so an arbitrary number of populations is supported.
  """
  @spec mesh2d(number_of_populations(), population_index()) :: neighbour_population_indices()
  def mesh2d(n, idx) when n > 1 do
    edge_size =
      n
      |> :math.sqrt()
      |> ceil()

    row = div(idx, edge_size)
    col = rem(idx, edge_size)

    vertical_nieghbours =
      [row - 1, row + 1]
      |> Enum.filter(&mesh2d_in_bound?(&1, edge_size))
      |> Enum.map(fn neighbour_row -> edge_size * neighbour_row + col end)

    horizontal_neighbours =
      [col - 1, col + 1]
      |> Enum.filter(&mesh2d_in_bound?(&1, edge_size))
      |> Enum.map(fn neighbour_col -> edge_size * row + neighbour_col end)

    (vertical_nieghbours ++ horizontal_neighbours)
    |> Enum.filter(fn idx -> idx < n end)
    |> Enum.sort()
  end

  defp mesh2d_in_bound?(row_or_col_idx, size) do
    row_or_col_idx >= 0 and row_or_col_idx < size
  end

  @doc """
  Represents a 3-dimensional mesh topology.

  The populations are arranged into a collection of square grids, but such a grid doesn't have
  to be complete, so an arbitrary number of populations is supported.
  """
  @spec mesh3d(number_of_populations(), population_index()) :: neighbour_population_indices()
  def mesh3d(n, idx) when n > 1 do
    edge_size =
      n
      |> :math.pow(1 / 3)
      |> ceil()

    matrix_size = edge_size * edge_size

    wall_idx = div(idx, matrix_size)
    offset = wall_idx * matrix_size

    row = div(idx - offset, edge_size)
    col = rem(idx - offset, edge_size)

    # same matrix
    vertical_nieghbours =
      [row - 1, row + 1]
      |> Enum.filter(&mesh2d_in_bound?(&1, edge_size))
      |> Enum.map(fn neighbour_row -> edge_size * neighbour_row + col + offset end)

    horizontal_neighbours =
      [col - 1, col + 1]
      |> Enum.filter(&mesh2d_in_bound?(&1, edge_size))
      |> Enum.map(fn neighbour_col -> edge_size * row + neighbour_col + offset end)

    # neighbour matrices
    matrix_neighbours =
      Enum.filter([idx - matrix_size, idx + matrix_size], fn idx -> idx >= 0 end)

    (vertical_nieghbours ++ horizontal_neighbours ++ matrix_neighbours)
    |> Enum.filter(fn idx -> idx < n end)
    |> Enum.sort()
  end

  @doc """
  Represents a fully connected topology.
  """
  @spec fully_connected(number_of_populations(), population_index()) ::
          neighbour_population_indices()
  def fully_connected(n, idx) when n > 1 do
    Enum.to_list(0..(n - 1)) -- [idx]
  end

  @doc """
  Represents a star topology.

  The populations are arranged into a star, and the one
  with `0` index resides in the middle of it.
  """
  @spec star(number_of_populations(), population_index()) ::
          neighbour_population_indices()
  def star(n, idx) when n > 1 do
    case idx do
      0 -> fully_connected(n, 0)
      _ -> [0]
    end
  end

  @doc """
  Creates an anonymous function that represents a user-defined topology.

  The topology map must include keys for all of the populations, even if one doesn't have any neighbours.
  """
  @spec from_map(%{population_index() => neighbour_population_indices()}) :: topology_fun()
  def from_map(topology_map) do
    indices = Map.keys(topology_map)

    max_idx = Enum.max(indices)
    expected_indices = Enum.to_list(0..max_idx)

    case expected_indices -- indices do
      [] ->
        :ok

      missing ->
        missing_string = missing |> Enum.map(&to_string/1) |> Enum.join(", ")

        raise ArgumentError,
              "expected #{max_idx + 1} entries in the topology map, but the following keys are missing: #{missing_string}"
    end

    for {from_idx, to_indices} <- topology_map,
        to_idx <- to_indices,
        to_idx not in 0..max_idx do
      raise ArgumentError,
            "expected population neighbours to be in [0, #{max_idx}], but found: #{to_idx} for population #{from_idx}"
    end

    fn n, idx ->
      expected_n = max_idx + 1

      unless n == expected_n do
        raise ArgumentError,
              "the topology was defined for #{expected_n} populations, but called with #{n}"
      end

      topology_map[idx]
    end
  end
end
