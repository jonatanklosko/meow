defmodule MeowNx.Op.Crossover do
  @moduledoc """
  Crossover operations backed by numerical definitions.

  This module provides a compatibility layer for `Meow`,
  while individual numerical definitions can be found
  in `MeowNx.Crossover`.
  """

  alias Meow.Op
  alias MeowNx.Crossover
  alias MeowNx.Utils

  @doc """
  Builds a uniform crossover operation.

  See `MeowNx.Crossover.uniform/2` for more details.
  """
  @spec uniform(float()) :: Op.t()
  def uniform(probability \\ 0.5) do
    opts = [probability: probability]

    %Op{
      name: "[Nx] Uniform crossover",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Crossover.uniform(&1, opts), [genomes], Utils.jit_opts(ctx))
        end)
      end
    }
  end

  @doc """
  Builds a single point crossover operation.

  See `MeowNx.Crossover.single_point/1` for more details.
  """
  @spec single_point() :: Op.t()
  def single_point() do
    %Op{
      name: "[Nx] Single point crossover",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Crossover.single_point(&1), [genomes], Utils.jit_opts(ctx))
        end)
      end
    }
  end

  @doc """
  Builds a blend-alpha crossover operation.

  See `MeowNx.Crossover.blend_alpha/2` for more details.
  """
  @spec blend_alpha(float()) :: Op.t()
  def blend_alpha(alpha \\ 0.5) do
    opts = [alpha: alpha]

    %Op{
      name: "[Nx] Blend-alpha crossover",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Crossover.blend_alpha(&1, opts), [genomes], Utils.jit_opts(ctx))
        end)
      end
    }
  end

  @doc """
  Builds a simulated binary crossover operation.

  See `MeowNx.Crossover.simulated_binary/2` for more details.
  """
  @spec simulated_binary(float()) :: Op.t()
  def simulated_binary(eta) do
    opts = [eta: eta]

    %Op{
      name: "[Nx] Simulated binary crossover",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Crossover.simulated_binary(&1, opts), [genomes], Utils.jit_opts(ctx))
        end)
      end
    }
  end
end
