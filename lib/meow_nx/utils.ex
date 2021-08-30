defmodule MeowNx.Utils do
  @moduledoc false

  import Nx.Defn

  @doc """
  Given a 2-dimensional tensor swaps each consecutive
  pairs of rows.

  ## Examples

      iex> t = Nx.iota({4, 2}, axis: 0)
      iex> MeowNx.Utils.swap_adjacent_rows(t)
      #Nx.Tensor<
        s64[4][2]
        [
          [1, 1],
          [0, 0],
          [3, 3],
          [2, 2]
        ]
      >
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

  ## Examples

      iex> t = Nx.tensor([[0, 0], [1, 1]])
      iex> MeowNx.Utils.duplicate_rows(t)
      #Nx.Tensor<
        s64[4][2]
        [
          [0, 0],
          [0, 0],
          [1, 1],
          [1, 1]
        ]
      >
  """
  defn duplicate_rows(t) do
    {n, m} = Nx.shape(t)
    twice_n = transform(n, &(&1 * 2))

    t
    |> Nx.tile([1, 2])
    |> Nx.reshape({twice_n, m})
  end

  @doc """
  Returns the cumulative sum of elements in the given
  1-dimensional tensor.

  ## Examples

      iex> MeowNx.Utils.cumulative_sum(Nx.tensor([1, 2, 3, 4]))
      #Nx.Tensor<
        s64[4]
        [1, 3, 6, 10]
      >
  """
  defn cumulative_sum(t) do
    {n} = Nx.shape(t)
    Nx.dot(lower_triangular(n), t)
  end

  defnp lower_triangular(n) do
    Nx.less_equal(
      Nx.iota({n, n}, axis: 1),
      Nx.iota({n, n}, axis: 0)
    )
  end
end
