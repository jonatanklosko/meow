defmodule MeowNx.Op.Mutation do
  @moduledoc """
  Mutation operations backed by numerical definitions.

  This module provides a compatibility layer for `Meow`,
  while individual numerical definitions can be found
  in `MeowNx.Mutation`.
  """

  alias Meow.Op
  alias MeowNx.Mutation
  alias MeowNx.Utils

  @doc """
  Builds a uniform replacement mutation operation.

  See `MeowNx.Mutation.replace_uniform/2` for more details.
  """
  @spec replace_uniform(float(), float(), float()) :: Op.t()
  def replace_uniform(probability, min, max) do
    opts = [probability: probability, min: min, max: max]

    %Op{
      name: "[Nx] Mutation replace uniform",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Mutation.replace_uniform(&1, opts), [genomes], Utils.jit_opts(ctx))
        end)
      end
    }
  end

  @doc """
  Builds a bit-flip mutation operation.

  See `MeowNx.Mutation.replace_uniform/2` for more details.
  """
  @spec bit_flip(float()) :: Op.t()
  def bit_flip(probability) do
    opts = [probability: probability]

    %Op{
      name: "[Nx] Mutation replace uniform",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Mutation.bit_flip(&1, opts), [genomes], Utils.jit_opts(ctx))
        end)
      end
    }
  end

  @doc """
  Builds a Gaussian shift mutation operation.

  See `MeowNx.Mutation.shift_gaussian/2` for more details.
  """
  @spec shift_gaussian(float(), keyword()) :: Op.t()
  def shift_gaussian(probability, opts \\ []) do
    opts = opts |> Keyword.take([:sigma]) |> Keyword.put(:probability, probability)

    %Op{
      name: "[Nx] Mutation shift Gaussian",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Mutation.shift_gaussian(&1, opts), [genomes], Utils.jit_opts(ctx))
        end)
      end
    }
  end
end
