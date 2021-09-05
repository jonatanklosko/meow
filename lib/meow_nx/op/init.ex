defmodule MeowNx.Op.Init do
  @moduledoc """
  Initialization operations backed by numerical definitions.

  This module provides a compatibility layer for `Meow`,
  while individual numerical definitions can be found
  in `MeowNx.Init`.
  """

  alias Meow.Op
  alias MeowNx.Init
  alias MeowNx.Utils

  @doc """
  Builds a random initialization operation for the real
  representation.

  See `MeowNx.Init.real_random_uniform/1` for more details.
  """
  @spec real_random_uniform(non_neg_integer(), non_neg_integer(), float(), float()) :: Op.t()
  def real_random_uniform(n, length, min, max) do
    opts = [n: n, length: length, min: min, max: max]

    %Op{
      name: "[Nx] Initialization random uniform",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        genomes = Nx.Defn.jit(fn -> Init.real_random_uniform(opts) end, [], Utils.jit_opts(ctx))
        %{population | genomes: genomes, representation_spec: MeowNx.RepresentationSpec}
      end
    }
  end

  @doc """
  Builds a random initialization operation for the binary
  representation.

  See `MeowNx.Init.binary_random_uniform/1` for more details.
  """
  @spec binary_random_uniform(non_neg_integer(), non_neg_integer()) :: Op.t()
  def binary_random_uniform(n, length) do
    opts = [n: n, length: length]

    %Op{
      name: "[Nx] Initialization random uniform",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        genomes = Nx.Defn.jit(fn -> Init.binary_random_uniform(opts) end, [], Utils.jit_opts(ctx))
        %{population | genomes: genomes, representation_spec: MeowNx.RepresentationSpec}
      end
    }
  end
end
