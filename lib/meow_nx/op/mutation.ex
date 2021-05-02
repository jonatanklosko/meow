defmodule MeowNx.Op.Mutation do
  import Nx.Defn
  alias Meow.Op

  def replace_random_uniform(probability, min, max) do
    opts = [probability: probability, min: min, max: max]

    %Op{
      name: "[Nx] Mutation replace random uniform",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, _ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&replace_random_uniform_impl(&1, opts), [genomes], compiler: EXLA)
        end)
      end
    }
  end

  defnp replace_random_uniform_impl(genomes, opts \\ []) do
    probability = opts[:probability]
    min = opts[:min]
    max = opts[:max]

    shape = Nx.shape(genomes)

    # Mutate each gene separately with the given probability
    sel = Nx.random_uniform(shape) |> Nx.less(probability)
    new = Nx.random_uniform(shape, min, max)
    Nx.select(sel, new, genomes)
  end
end
