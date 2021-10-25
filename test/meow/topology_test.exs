defmodule Meow.TopologyTest do
  use ExUnit.Case, async: true

  alias Meow.Topology

  test "ring/2" do
    assert topology_to_map(&Topology.ring/2, 3) == %{
             0 => [1],
             1 => [2],
             2 => [0]
           }

    assert topology_to_map(&Topology.ring/2, 5) == %{
             0 => [1],
             1 => [2],
             2 => [3],
             3 => [4],
             4 => [0]
           }
  end

  test "mesh2d/2" do
    # 0 1
    # 2
    assert topology_to_map(&Topology.mesh2d/2, 3) == %{
             0 => [1, 2],
             1 => [0],
             2 => [0]
           }

    # 0 1
    # 2 3
    assert topology_to_map(&Topology.mesh2d/2, 4) == %{
             0 => [1, 2],
             1 => [0, 3],
             2 => [0, 3],
             3 => [1, 2]
           }

    # 0 1 2
    # 3 4 5
    # 6 7
    assert topology_to_map(&Topology.mesh2d/2, 8) == %{
             0 => [1, 3],
             1 => [0, 2, 4],
             2 => [1, 5],
             3 => [0, 4, 6],
             4 => [1, 3, 5, 7],
             5 => [2, 4],
             6 => [3, 7],
             7 => [4, 6]
           }
  end

  test "mesh3d/2" do
    # 0   1   2
    # 3   4   5
    # 6   7   8

    # 9  10  11
    # 12 13  14
    # 15 16  17

    # 18 19  20
    assert topology_to_map(&Topology.mesh3d/2, 21) == %{
             0 => [1, 3, 9],
             1 => [0, 2, 4, 10],
             2 => [1, 5, 11],
             3 => [0, 4, 6, 12],
             4 => [1, 3, 5, 7, 13],
             5 => [2, 4, 8, 14],
             6 => [3, 7, 15],
             7 => [4, 6, 8, 16],
             8 => [5, 7, 17],
             9 => [0, 10, 12, 18],
             10 => [1, 9, 11, 13, 19],
             11 => [2, 10, 14, 20],
             12 => [3, 9, 13, 15],
             13 => [4, 10, 12, 14, 16],
             14 => [5, 11, 13, 17],
             15 => [6, 12, 16],
             16 => [7, 13, 15, 17],
             17 => [8, 14, 16],
             18 => [9, 19],
             19 => [10, 18, 20],
             20 => [11, 19]
           }
  end

  test "fully_connected/2" do
    assert topology_to_map(&Topology.fully_connected/2, 2) == %{
             0 => [1],
             1 => [0]
           }

    assert topology_to_map(&Topology.fully_connected/2, 4) == %{
             0 => [1, 2, 3],
             1 => [0, 2, 3],
             2 => [0, 1, 3],
             3 => [0, 1, 2]
           }
  end

  test "star/2" do
    assert topology_to_map(&Topology.star/2, 2) == %{
             0 => [1],
             1 => [0]
           }

    assert topology_to_map(&Topology.star/2, 4) == %{
             0 => [1, 2, 3],
             1 => [0],
             2 => [0],
             3 => [0]
           }
  end

  describe "from_map/1" do
    test "raises an error when the topology map is missing indices" do
      assert_raise ArgumentError,
                   ~s/expected 3 entries in the topology map, but the following keys are missing: 1/,
                   fn ->
                     Topology.from_map(%{0 => [], 2 => []})
                   end
    end

    test "raises an error when topology map values contain population indices smaller than 0" do
      assert_raise ArgumentError,
                   ~s/expected population neighbours to be in [0, 2], but found: -1 for population 1/,
                   fn ->
                     Topology.from_map(%{0 => [1], 1 => [-1, 0], 2 => [0]})
                   end
    end

    test "raises an error when topology map values contain population indices bigger than max_idx" do
      assert_raise ArgumentError,
                   ~s/expected population neighbours to be in [0, 2], but found: 3 for population 2/,
                   fn ->
                     Topology.from_map(%{0 => [1], 1 => [0, 2], 2 => [0, 3]})
                   end
    end

    test "returned topology_fun raises an error if number of populations doesn't match the one in topology map" do
      topology_fun = Topology.from_map(%{0 => [1], 1 => [0]})

      assert_raise ArgumentError,
                   ~s/the topology was defined for 2 populations, but called with 3/,
                   fn ->
                     topology_fun.(3, 0)
                   end
    end

    test "returned topology_fun returns a neighbour indices list for a population with a given index" do
      topology_fun = Topology.from_map(%{0 => [1, 2], 1 => [0], 2 => []})

      assert topology_to_map(topology_fun, 3) == %{
               0 => [1, 2],
               1 => [0],
               2 => []
             }
    end
  end

  defp topology_to_map(topology_fun, n) do
    for idx <- 0..(n - 1), into: %{} do
      neighbour_indices = topology_fun.(n, idx)
      {idx, neighbour_indices}
    end
  end
end
