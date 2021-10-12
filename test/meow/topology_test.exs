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

  test "fully_connected/2" do
    assert topology_to_map(&Topology.fully_connected/2, 1) == %{
             0 => []
           }

    assert topology_to_map(&Topology.fully_connected/2, 4) == %{
             0 => [1, 2, 3],
             1 => [0, 2, 3],
             2 => [0, 1, 3],
             3 => [0, 1, 2]
           }
  end

  defp topology_to_map(topology_fun, n) do
    for idx <- 0..(n - 1), into: %{} do
      neighbour_indices = topology_fun.(n, idx)
      {idx, neighbour_indices}
    end
  end
end
