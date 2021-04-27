defmodule MeowNx.Utils do
  import Nx.Defn

  # This is a hack for doing gather on 2d tensor.
  # Hopefully gather comes along: https://github.com/elixir-nx/nx/issues/223
  #
  # `t` is a 2d tensor and `idx` is a 1d tensor with indices of rows
  # to select for the new 2d tensor.
  defn gather_rows(t, idx) do
    # n is the number of rows in the resulting 2d tensor
    {n} = Nx.shape(idx)
    {:u, _} = Nx.type(idx)
    {x, _y} = Nx.shape(t)

    # Each row is a one-hot encoding of which row from `t` to choose
    selector = Nx.equal(Nx.reshape(idx, {n, 1}), Nx.iota({1, x}))
    Nx.dot(selector, t)
  end
end
