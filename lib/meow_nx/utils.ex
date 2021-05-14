defmodule MeowNx.Utils do
  @moduledoc false

  import Nx.Defn

  @doc """
  Given a 2-dimensional tensor and a 1-dimensional tensor
  of indices, builds a new 2-dimensional tensor by stacking
  rows from the original tensor at the given indices.

  This operation is a specific case of a generic *gather* operation,
  which is not yet implemented in `Nx`, but is on the roadmap.
  See https://github.com/elixir-nx/nx/issues/223
  """
  # TODO: replace with `Nx.gather` once it's there
  defn gather_rows(t, idx) do
    {n, _} = Nx.shape(t)
    {result_n} = Nx.shape(idx)

    # Each selector row is a one-hot encoding of which row from `t` to choose
    selector =
      Nx.equal(
        Nx.reshape(idx, {result_n, 1}),
        Nx.iota({1, n})
      )

    Nx.dot(selector, t)
  end

  @doc """
  Same as `gather_rows/2` but for a 1-dimensional tensor.
  """
  defn gather_scalars(t, idx) do
    {n} = Nx.shape(t)
    {final_n} = Nx.shape(idx)

    t
    |> Nx.reshape({n, 1})
    |> gather_rows(idx)
    |> Nx.reshape({final_n})
  end

  @doc """
  Given a 2-dimensional tensor swaps each consecutive
  pair of rows.
  """
  defn swap_adjacent_rows(t) do
    {n, m} = Nx.shape(t)
    half_n = transform(n, &div(&1, 2))

    t
    |> Nx.reshape({half_n, 2, m})
    |> Nx.reverse(axes: [1])
    |> Nx.reshape({n, m})
  end

  @doc """
  Given a 2-dimensional tensor replicates each row into
  two adjacent rows.
  """
  defn duplicate_rows(t) do
    {n, m} = Nx.shape(t)
    twice_n = transform(n, &(&1 * 2))

    t
    |> Nx.tile([1, 2])
    |> Nx.reshape({twice_n, m})
  end
end
