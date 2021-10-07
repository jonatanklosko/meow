defmodule MeowNx.CrossoverTest do
  use ExUnit.Case, async: true

  alias MeowNx.Crossover

  describe "multi_point/2" do
    test "raises an error when too many points are specified" do
      genomes = Nx.tensor([[1, 2], [1, 2]])

      assert_raise ArgumentError, "2-point crossover is not valid for genome of length 2", fn ->
        Crossover.multi_point(genomes, points: 2)
      end
    end

    test "deterministic case where every second gene is swapped (points == length - 1)" do
      genomes =
        Nx.tensor([
          [1, 2, 3, 4],
          [-1, -2, -3, -4],
          [11, 22, 33, 44],
          [-11, -22, -33, -44]
        ])

      assert Crossover.multi_point(genomes, points: 3) ==
               Nx.tensor([
                 [1, -2, 3, -4],
                 [-1, 2, -3, 4],
                 [11, -22, 33, -44],
                 [-11, 22, -33, 44]
               ])
    end

    test "property: the number of crossover points matches the specified one" do
      genomes = Nx.random_uniform({100, 100})
      points = 10

      offsprings = Crossover.multi_point(genomes, points: points)

      same_gene? = Nx.equal(genomes, offsprings)

      number_of_points =
        same_gene?
        |> Nx.window_sum({1, 2})
        |> Nx.remainder(2)
        |> Nx.sum(axes: [1])

      assert Nx.equal(number_of_points, Nx.tensor(points))
    end
  end
end
