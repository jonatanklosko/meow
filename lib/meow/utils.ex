defmodule Meow.Utils do
  @moduledoc false

  import Nx.Defn

  defmacro fetch_opts!(opts, keys) do
    quote bind_quoted: [opts: opts, keys: keys] do
      transform(opts, fn opts ->
        for key <- keys do
          case Keyword.fetch(opts, key) do
            {:ok, value} -> value
            :error -> raise "missing required key #{inspect(key)} in options #{inspect(opts)}"
          end
        end
      end)
    end
  end

  @doc """
  A version of `Nx.take/3` with a leading batch dimension.

  Conceptually, this function zips `tensor` with `indices` and then
  applies `Nx.take/3` along the first axis for every pair.

  ## Examples

      iex> t =
      ...>   Nx.tensor([
      ...>     [
      ...>       [1, 1],
      ...>       [2, 2]
      ...>     ],
      ...>     [
      ...>       [3, 3],
      ...>       [4, 4]
      ...>     ]
      ...>   ])
      iex> idx = Nx.tensor([[1, 0], [1, 1]])
      iex> Meow.Utils.batched_take(t, idx)
      #Nx.Tensor<
        s64[2][2][2]
        [
          [
            [2, 2],
            [1, 1]
          ],
          [
            [4, 4],
            [4, 4]
          ]
        ]
      >

  ## Error cases

      iex> Meow.Utils.batched_take(Nx.tensor([[1, 2], [3, 4]]), Nx.tensor([1]))
      ** (ArgumentError) expected tensor and indices with the same leading axis size, got: {2, 2} and {1}

  """
  defn batched_take(tensor, idx) do
    {batch_size, axis_size, flat_shape, final_shape} =
      transform({tensor, idx}, fn {tensor, idx} ->
        tensor_shape = Nx.shape(tensor)
        idx_shape = Nx.shape(idx)

        unless Elixir.Kernel.==(elem(tensor_shape, 0), elem(idx_shape, 0)) do
          raise ArgumentError,
                "expected tensor and indices with the same leading axis size, got: #{inspect(tensor_shape)} and #{inspect(idx_shape)}"
        end

        [batch_size, axis_size | inner_sizes] = Tuple.to_list(tensor_shape)

        flat_shape = List.to_tuple([batch_size * axis_size | inner_sizes])
        final_shape = List.to_tuple(Tuple.to_list(idx_shape) ++ inner_sizes)
        {batch_size, axis_size, flat_shape, final_shape}
      end)

    flat_idx =
      idx
      |> Nx.reshape({batch_size, :auto})
      |> Nx.add(Nx.iota({batch_size, 1}) * axis_size)
      |> Nx.flatten()

    tensor
    |> Nx.reshape(flat_shape)
    |> Nx.take(flat_idx)
    |> Nx.reshape(final_shape)
  end

  @doc """
  Returns the cumulative sum of elements along an axis.

  ## Options

    * `:axis` - the axis to sum elements along. Defaults to `0`

  ## Examples

      iex> Meow.Utils.cumulative_sum(Nx.tensor([1, 2, 3, 4]))
      #Nx.Tensor<
        s64[4]
        [1, 3, 6, 10]
      >

      iex> Meow.Utils.cumulative_sum(Nx.iota({3, 3}), axis: 1)
      #Nx.Tensor<
        s64[3][3]
        [
          [0, 1, 3],
          [3, 7, 12],
          [6, 13, 21]
        ]
      >

  """
  defn cumulative_sum(tensor, opts \\ []) do
    opts = keyword!(opts, axis: 0)
    axis = Nx.axis_index(tensor, opts[:axis])

    {padding, window_shape} =
      transform(tensor, fn tensor ->
        size = Nx.axis_size(tensor, axis)
        rank = Nx.rank(tensor)

        padding =
          List.duplicate({0, 0}, rank)
          |> List.replace_at(axis, {size - 1, 0})

        window_shape =
          List.duplicate(1, rank)
          |> List.to_tuple()
          |> put_elem(axis, size)

        {padding, window_shape}
      end)

    Nx.window_sum(tensor, window_shape, padding: padding)
  end

  @doc """
  Swaps consecutive slices of length 1 along the given axis.

  ## Options

    * `:axis` - the axis to swap slices along. Defaults to `0`

  ## Examples

      iex> Meow.Utils.swap_pairs_along_axis(Nx.tensor([0, 1, 2, 3]))
      #Nx.Tensor<
        s64[4]
        [1, 0, 3, 2]
      >

      iex> Meow.Utils.swap_pairs_along_axis(Nx.iota({4, 4}))
      #Nx.Tensor<
        s64[4][4]
        [
          [4, 5, 6, 7],
          [0, 1, 2, 3],
          [12, 13, 14, 15],
          [8, 9, 10, 11]
        ]
      >

      iex> Meow.Utils.swap_pairs_along_axis(Nx.iota({4, 4}), axis: 1)
      #Nx.Tensor<
        s64[4][4]
        [
          [1, 0, 3, 2],
          [5, 4, 7, 6],
          [9, 8, 11, 10],
          [13, 12, 15, 14]
        ]
      >

  """
  defn swap_pairs_along_axis(tensor, opts \\ []) do
    opts = keyword!(opts, axis: 0)
    axis = Nx.axis_index(tensor, opts[:axis])

    shape = Nx.shape(tensor)

    {paired_shape, pair_axis} =
      transform({shape, axis}, fn {shape, axis} ->
        axis_size = elem(shape, axis)

        unless Elixir.Kernel.==(rem(axis_size, 2), 0) do
          raise ArgumentError, "expected axis size to be even, but got #{inspect(axis_size)}"
        end

        paired_shape =
          shape
          |> put_elem(axis, div(axis_size, 2))
          |> Tuple.insert_at(axis + 1, 2)

        {paired_shape, axis + 1}
      end)

    tensor
    |> Nx.reshape(paired_shape)
    |> Nx.reverse(axes: [pair_axis])
    |> Nx.reshape(shape)
  end

  @doc """
  Repeats elements in tensor along the given axis.

  The duplicated elements are adjacent to the original one.

  ## Options

    * `:axis` - the axis to swap slices along. Defaults to `0`

    * `:n` - how many times each element should appear. Defaults to `2`

  ## Examples

      iex> Meow.Utils.duplicate_along_axis(Nx.tensor([0, 1, 2]))
      #Nx.Tensor<
        s64[6]
        [0, 0, 1, 1, 2, 2]
      >

      iex> Meow.Utils.duplicate_along_axis(Nx.tensor([0, 1, 2]), n: 3)
      #Nx.Tensor<
        s64[9]
        [0, 0, 0, 1, 1, 1, 2, 2, 2]
      >

      iex> Meow.Utils.duplicate_along_axis(Nx.iota({2, 2}))
      #Nx.Tensor<
        s64[4][2]
        [
          [0, 1],
          [0, 1],
          [2, 3],
          [2, 3]
        ]
      >

      iex> Meow.Utils.duplicate_along_axis(Nx.iota({2, 2}), axis: 1)
      #Nx.Tensor<
        s64[2][4]
        [
          [0, 0, 1, 1],
          [2, 2, 3, 3]
        ]
      >

  """
  defn duplicate_along_axis(tensor, opts \\ []) do
    opts = keyword!(opts, axis: 0, n: 2)
    axis = Nx.axis_index(tensor, opts[:axis])
    n = opts[:n]

    shape = Nx.shape(tensor)

    {pre_shape, broadcast_shape, post_shape} =
      transform({shape, axis, n}, fn {shape, axis, n} ->
        axis_size = elem(shape, axis)
        pre_shape = Tuple.insert_at(shape, axis + 1, 1)
        broadcast_shape = Tuple.insert_at(shape, axis + 1, n)
        post_shape = put_elem(shape, axis, axis_size * n)
        {pre_shape, broadcast_shape, post_shape}
      end)

    tensor
    |> Nx.reshape(pre_shape)
    |> Nx.broadcast(broadcast_shape)
    |> Nx.reshape(post_shape)
  end

  @doc """
  Returns a tensor of random indices on the interval `[:min, :max)`
  without replacement (repetitions).

  The resulting tensor has `:shape` with random indices `:axis`.
  """
  defn random_idx_without_replacement(opts \\ []) do
    opts = keyword!(opts, [:shape, :min, :max, :axis])
    shape = opts[:shape]
    min = opts[:min]
    max = opts[:max]
    axis = opts[:axis]

    # We use argsort on random numbers to generate shuffled indices
    # and then we slice them according to the sample size

    range = max - min

    sample_size = transform(shape, &elem(&1, axis))
    random_shape = transform(shape, &put_elem(&1, axis, range))

    random_shape
    |> Nx.random_uniform()
    |> Nx.argsort(axis: axis)
    |> Nx.slice_along_axis(0, sample_size, axis: axis)
    |> Nx.add(min)
  end

  @doc """
  Sorts permutations along the given axis.

  Each sorted sequence must be a permuation of indices and therefore
  it already includes the order information, which means that argsort
  can be computed in linear time.

  This gives the same value as `Nx.argsort/2` with `:axis`, however
  it is more efficient by levaraging the outlined properties.

  ## Examples

      iex> Meow.Utils.permutation_argsort(Nx.tensor([3, 1, 0, 2]), axis: 0)
      #Nx.Tensor<
        s64[4]
        [2, 1, 3, 0]
      >

      iex> Meow.Utils.permutation_argsort(Nx.tensor([[3, 1, 0, 2], [2, 0, 1, 3]]), axis: 1)
      #Nx.Tensor<
        s64[2][4]
        [
          [2, 1, 3, 0],
          [1, 2, 0, 3]
        ]
      >

      iex> Meow.Utils.permutation_argsort(Nx.tensor([[3, 2], [1, 0], [0, 1], [2, 3]]), axis: 0)
      #Nx.Tensor<
        s64[4][2]
        [
          [2, 1],
          [1, 2],
          [3, 0],
          [0, 3]
        ]
      >

  """
  defn permutation_argsort(permutations, opts \\ []) do
    opts = keyword!(opts, [:axis])
    axis = Nx.axis_index(permutations, opts[:axis])

    type = Nx.type(permutations)

    empty = Nx.broadcast(Nx.tensor(0, type: type), permutations)

    indices =
      transform({permutations, axis}, fn {permutations, axis} ->
        permutations
        |> Nx.axes()
        |> Enum.map(fn
          ^axis -> permutations
          axis -> Nx.iota(permutations, axis: axis)
        end)
        |> Nx.stack(axis: -1)
        |> Nx.reshape({:auto, Nx.rank(permutations)})
      end)

    iota = permutations |> Nx.iota(type: type, axis: axis) |> Nx.flatten()

    # We use each permutation as indexing for 1-dimensional iota
    Nx.indexed_add(empty, indices, iota)
  end

  @doc """
  Shifts elements in `tensor` along the given axis.

  The `offsets` tensor must include an integer for every sequence
  of elements along the given axis, hence it has one dimension
  less than `tensor`.

  A positive offset shifts elements to higher indices, while a
  negative one does the reverse. The behaviour for invalid offset
  values is undefined.

  ## Options

    * `:axis` - the axis to shift elements along. Defaults to `0`

  ## Examples

      iex> Meow.Utils.shift(Nx.iota({4}), 2)
      #Nx.Tensor<
        s64[4]
        [2, 3, 0, 1]
      >

      iex> Meow.Utils.shift(Nx.iota({4}), -1)
      #Nx.Tensor<
        s64[4]
        [1, 2, 3, 0]
      >

      iex> Meow.Utils.shift(Nx.iota({3, 3}), Nx.tensor([-1, 0, 1]), axis: 1)
      #Nx.Tensor<
        s64[3][3]
        [
          [1, 2, 0],
          [3, 4, 5],
          [8, 6, 7]
        ]
      >

      iex> Meow.Utils.shift(Nx.iota({2, 2, 2}), Nx.tensor([[1, 0], [0, 1]]), axis: 0)
      #Nx.Tensor<
        s64[2][2][2]
        [
          [
            [4, 1],
            [2, 7]
          ],
          [
            [0, 5],
            [6, 3]
          ]
        ]
      >

  """
  defn shift(tensor, offsets, opts \\ []) do
    opts = keyword!(opts, axis: 0)
    axis = Nx.axis_index(tensor, opts[:axis])

    transform({tensor, offsets, axis}, &validate_shift!/1)

    axis_size = Nx.axis_size(tensor, axis)
    offsets = Nx.new_axis(offsets, axis)

    idx = Nx.iota(tensor, axis: axis)
    shifted_idx = Nx.remainder(idx - offsets + axis_size, axis_size)
    Nx.take_along_axis(tensor, shifted_idx, axis: axis)
  end

  defp validate_shift!({tensor, offsets, axis}) do
    shape = Nx.shape(tensor)
    offsets_type = Nx.type(offsets)
    offsets_shape = Nx.shape(offsets)

    unless Nx.Type.integer?(offsets_type) do
      raise ArgumentError, "offsets must be an integer tensor, got #{inspect(offsets_type)}"
    end

    expected_offsets_shape = Tuple.delete_at(shape, axis)

    unless offsets_shape == expected_offsets_shape do
      raise ArgumentError,
            "expected offsets to have shape #{inspect(expected_offsets_shape)}, got: #{inspect(offsets_shape)}"
    end
  end
end
