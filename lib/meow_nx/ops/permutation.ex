defmodule MeowNx.Ops.Permutation do
  @moduledoc """
  Permutation operations backed by numerical definitions.
  """

  alias Meow.{Op, Population}
  alias MeowNx.Permutation

  @doc """
  Builds a random initializer for the permutation representation.

  See `MeowNx.Permutation.init_random/1` for more details.
  """
  @doc type: :init
  @spec init_permutation_random(non_neg_integer(), non_neg_integer()) :: Op.t()
  def init_permutation_random(n, length) do
    opts = [n: n, length: length]

    %Op{
      name: "[Nx] Initialization: permutation random",
      requires_fitness: false,
      invalidates_fitness: true,
      in_representations: :any,
      out_representation: MeowNx.permutation_representation(),
      impl: fn population, _ctx ->
        Meow.Population.map_genomes(population, fn _genomes ->
          Permutation.init_random(opts)
        end)
      end
    }
  end

  @doc """
  Builds a single point crossover operation adopted for permutations.

  See `MeowNx.Permutation.crossover_single_point/1` for more details.
  """
  @doc type: :crossover
  @spec crossover_single_point() :: Op.t()
  def crossover_single_point() do
    %Op{
      name: "[Nx] Crossover: single point",
      requires_fitness: false,
      invalidates_fitness: true,
      in_representations: [MeowNx.permutation_representation()],
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          Permutation.crossover_single_point(genomes)
        end)
      end
    }
  end

  @doc """
  Builds an order crossover operation.

  See `MeowNx.Permutation.crossover_order/1` for more details.
  """
  @doc type: :crossover
  @spec crossover_order() :: Op.t()
  def crossover_order() do
    %Op{
      name: "[Nx] Crossover: order",
      requires_fitness: false,
      invalidates_fitness: true,
      in_representations: [MeowNx.permutation_representation()],
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          Permutation.crossover_order(genomes)
        end)
      end
    }
  end

  @doc """
  Builds an position based crossover operation.

  See `MeowNx.Permutation.crossover_position_based/1` for more details.
  """
  @doc type: :crossover
  @spec crossover_position_based() :: Op.t()
  def crossover_position_based() do
    %Op{
      name: "[Nx] Crossover: position based",
      requires_fitness: false,
      invalidates_fitness: true,
      in_representations: [MeowNx.permutation_representation()],
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          Permutation.crossover_position_based(genomes)
        end)
      end
    }
  end

  @doc """
  Builds a linear order crossover operation.

  See `MeowNx.Permutation.crossover_linear_order/1` for more details.
  """
  @doc type: :crossover
  @spec crossover_linear_order() :: Op.t()
  def crossover_linear_order() do
    %Op{
      name: "[Nx] Crossover: linear order",
      requires_fitness: false,
      invalidates_fitness: true,
      in_representations: [MeowNx.permutation_representation()],
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          Permutation.crossover_linear_order(genomes)
        end)
      end
    }
  end

  @doc """
  Builds an inversion mutation operation.

  See `MeowNx.Permutation.mutation_inversion/2` for more details.
  """
  @doc type: :mutation
  @spec mutation_inversion(float()) :: Op.t()
  def mutation_inversion(probability) do
    opts = [probability: probability]

    %Op{
      name: "[Nx] Mutation: inversion",
      requires_fitness: false,
      invalidates_fitness: true,
      in_representations: [MeowNx.permutation_representation()],
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          Permutation.mutation_inversion(genomes, opts)
        end)
      end
    }
  end

  @doc """
  Builds a swap mutation operation.

  See `MeowNx.Permutation.mutation_swap/2` for more details.
  """
  @doc type: :mutation
  @spec mutation_swap(float()) :: Op.t()
  def mutation_swap(probability) do
    opts = [probability: probability]

    %Op{
      name: "[Nx] Mutation: swap",
      requires_fitness: false,
      invalidates_fitness: true,
      in_representations: [MeowNx.permutation_representation()],
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          Permutation.mutation_swap(genomes, opts)
        end)
      end
    }
  end
end
