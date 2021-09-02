defmodule MeowNx.Op.Selection do
  @moduledoc """
  Selection operations backed by numerical definitions.

  This module provides a compatibility layer for `Meow`,
  while individual numerical definitions can be found
  in `MeowNx.Selection`.
  """

  alias Meow.Op
  alias MeowNx.Selection
  alias MeowNx.Utils

  @doc """
  Builds a tournament selection operation.

  See `MeowNx.Selection.tournament/3` for more details.
  """
  @spec tournament(non_neg_integer()) :: Op.t()
  def tournament(n) do
    opts = [n: n]

    %Op{
      name: "[Nx] Selection tournament",
      requires_fitness: true,
      invalidates_fitness: false,
      impl: fn population, ctx ->
        Op.map_genomes_and_fitness(population, fn genomes, fitness ->
          Nx.Defn.jit(
            &Selection.tournament(&1, &2, opts),
            [genomes, fitness],
            Utils.jit_opts(ctx)
          )
        end)
      end
    }
  end

  @doc """
  Builds a natural selection operation.

  See `MeowNx.Selection.natural/3` for more details.
  """
  @spec natural(non_neg_integer()) :: Op.t()
  def natural(n) do
    opts = [n: n]

    %Op{
      name: "[Nx] Selection natural",
      requires_fitness: true,
      invalidates_fitness: false,
      impl: fn population, ctx ->
        Op.map_genomes_and_fitness(population, fn genomes, fitness ->
          Nx.Defn.jit(&Selection.natural(&1, &2, opts), [genomes, fitness], Utils.jit_opts(ctx))
        end)
      end
    }
  end
end
