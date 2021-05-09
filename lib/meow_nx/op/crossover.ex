defmodule MeowNx.Op.Crossover do
  alias Meow.Op
  alias MeowNx.Crossover

  def uniform(probability \\ 0.5) do
    opts = [probability: probability]

    %Op{
      name: "[Nx] Uniform crossover",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, _ctx ->
        Op.map_genomes(population, fn genomes ->
          # TODO: make compiler (and generally other options)
          # configurable globally for the model
          Nx.Defn.jit(&Crossover.uniform(&1, opts), [genomes], compiler: EXLA)
        end)
      end
    }
  end

  def single_point() do
    %Op{
      name: "[Nx] Single point crossover",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, _ctx ->
        Op.map_genomes(population, fn genomes ->
          # TODO: make compiler (and generally other options)
          # configurable globally for the model
          Nx.Defn.jit(&Crossover.single_point(&1), [genomes], compiler: EXLA)
        end)
      end
    }
  end

  def blend_alpha(alpha \\ 0.5) do
    opts = [alpha: alpha]

    %Op{
      name: "[Nx] Blend-alpha crossover",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, _ctx ->
        Op.map_genomes(population, fn genomes ->
          # TODO: make compiler (and generally other options)
          # configurable globally for the model
          Nx.Defn.jit(&Crossover.blend_alpha(&1, opts), [genomes], compiler: EXLA)
        end)
      end
    }
  end

  def simulated_binary(eta) do
    opts = [eta: eta]

    %Op{
      name: "[Nx] Simulated binary crossover",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, _ctx ->
        Op.map_genomes(population, fn genomes ->
          # TODO: make compiler (and generally other options)
          # configurable globally for the model
          Nx.Defn.jit(&Crossover.simulated_binary(&1, opts), [genomes], compiler: EXLA)
        end)
      end
    }
  end
end
