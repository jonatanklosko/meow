defmodule MeowNx.Op.Mutation do
  alias Meow.Op
  alias MeowNx.Mutation

  def replace_uniform(probability, min, max) do
    opts = [probability: probability, min: min, max: max]

    %Op{
      name: "[Nx] Mutation replace uniform",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, _ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Mutation.replace_uniform(&1, opts), [genomes], compiler: EXLA)
        end)
      end
    }
  end

  def shift_gaussian(probability, opts \\ []) do
    opts = [probability: probability, sigma: opts[:sigma] || 1]

    %Op{
      name: "[Nx] Mutation shift Gaussian",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, _ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Mutation.shift_gaussian(&1, opts), [genomes], compiler: EXLA)
        end)
      end
    }
  end
end
