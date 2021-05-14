defmodule MeowNx.Op.Selection do
  alias Meow.Op
  alias MeowNx.Selection

  def tournament(n) do
    opts = [n: n]

    %Op{
      name: "[Nx] Selection tournament",
      requires_fitness: true,
      invalidates_fitness: false,
      impl: fn population, _ctx ->
        Op.map_genomes_and_fitness(population, fn genomes, fitness ->
          Nx.Defn.jit(&Selection.tournament(&1, &2, opts), [genomes, fitness], compiler: EXLA)
        end)
      end
    }
  end

  def natural(n) do
    opts = [n: n]

    %Op{
      name: "[Nx] Selection natural",
      requires_fitness: true,
      invalidates_fitness: false,
      impl: fn population, _ctx ->
        Op.map_genomes_and_fitness(population, fn genomes, fitness ->
          Nx.Defn.jit(&Selection.natural(&1, &2, opts), [genomes, fitness], compiler: EXLA)
        end)
      end
    }
  end
end
