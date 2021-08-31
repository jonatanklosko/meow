defmodule Meow.Utils do
  @moduledoc false

  @doc """
  Distributes items evenly into the given number of chunks.

  ## Examples

      iex> Meow.Utils.split_evenly([1, 2, 3, 4], 2)
      [[1, 2], [3, 4]]

      iex> Meow.Utils.split_evenly([1, 2, 3, 4, 5, 6, 7], 3)
      [[1, 2, 3], [4, 5], [6, 7]]

      iex> Meow.Utils.split_evenly([1], 2)
      [[1], []]
  """
  def split_evenly(list, number_of_chunks) do
    split_evenly(list, number_of_chunks, [])
  end

  defp split_evenly([], 0, acc), do: Enum.reverse(acc)

  defp split_evenly(list, number_of_chunks, acc) do
    chunk_size = ceil(length(list) / number_of_chunks)
    {group, rest} = Enum.split(list, chunk_size)
    split_evenly(rest, number_of_chunks - 1, [group | acc])
  end
end
