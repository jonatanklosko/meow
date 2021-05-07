defmodule MeowNx.Op.Selection do
  import Nx.Defn
  alias Meow.Op
  alias MeowNx.Utils

  def tournament(n) do
    # TODO: support percentage, something like {:fraction, 0.2}
    opts = [n: n]

    %Op{
      name: "[Nx] Selection tournament",
      requires_fitness: true,
      invalidates_fitness: false,
      impl: fn population, _ctx ->
        Op.map_genomes_and_fitness(population, fn genomes, fitness ->
          Nx.Defn.jit(&tournament_impl(&1, &2, opts), [genomes, fitness], compiler: EXLA)
        end)
      end
    }
  end

  defnp tournament_impl(genomes, fitness, opts \\ []) do
    final_n = opts[:n]

    {n, length} = Nx.shape(genomes)

    # Reshape fitness into 2D, so our `gather_rows` works fine
    fitness = Nx.reshape(fitness, {n, 1})

    idx1 = Nx.random_uniform({final_n}, 0, n, type: {:u, 32})
    idx2 = Nx.random_uniform({final_n}, 0, n, type: {:u, 32})

    parents1 = Utils.gather_rows(genomes, idx1)
    fitness1 = Utils.gather_rows(fitness, idx1)

    parents2 = Utils.gather_rows(genomes, idx2)
    fitness2 = Utils.gather_rows(fitness, idx2)

    best_fitness = Nx.greater(fitness1, fitness2)
    best_genomes = Nx.broadcast(best_fitness, {final_n, length})

    fitness = Nx.select(best_fitness, fitness1, fitness2) |> Nx.reshape({final_n})
    genomes = Nx.select(best_genomes, parents1, parents2)

    {genomes, fitness}
  end

  def natural(n) do
    # TODO: support percentage, something like {:fraction, 0.2}
    # TODO: validate that n is not larget than population's
    opts = [n: n]

    %Op{
      name: "[Nx] Selection natural",
      requires_fitness: true,
      invalidates_fitness: false,
      impl: fn population, _ctx ->
        Op.map_genomes_and_fitness(population, fn genomes, fitness ->
          Nx.Defn.jit(&natural_impl(&1, &2, opts), [genomes, fitness], compiler: EXLA)
        end)
      end
    }
  end

  defnp natural_impl(genomes, fitness, opts \\ []) do
    final_n = opts[:n]
    {n, _} = Nx.shape(genomes)

    best_fitness_idx = Nx.argsort(fitness, comparator: :desc)[0..(final_n - 1)]
    best_genomes = Utils.gather_rows(genomes, best_fitness_idx)

    # Reshape fitness into 2D, so our `gather_rows` works fine
    fitness = Nx.reshape(fitness, {n, 1})
    best_fitness = Utils.gather_rows(fitness, best_fitness_idx)

    {best_genomes, best_fitness}
  end
end
