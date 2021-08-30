defmodule MeowNx.Init do
  @moduledoc """
  Genomes initializers for the tensor representation.
  """

  import Nx.Defn

  def real_random_uniform(n, length, min, max) do
    fn ->
      genomes = real_random_uniform_impl(n: n, length: length, min: min, max: max)
      {genomes, MeowNx.RepresentationSpec}
    end
  end

  defn real_random_uniform_impl(opts \\ []) do
    opts = keyword!(opts, [:n, :length, :min, :max])
    n = opts[:n]
    length = opts[:length]
    min = opts[:min]
    max = opts[:max]

    Nx.random_uniform({n, length}, min, max)
  end

  def binary_random_uniform(n, length) do
    fn ->
      genomes = binary_random_uniform_impl(n: n, length: length)
      {genomes, MeowNx.RepresentationSpec}
    end
  end

  defn binary_random_uniform_impl(opts \\ []) do
    opts = keyword!(opts, [:n, :length])
    n = opts[:n]
    length = opts[:length]

    Nx.random_uniform({n, length}, 0, 2) |> Nx.as_type({:u, 8})
  end
end
