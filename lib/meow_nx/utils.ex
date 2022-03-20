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
  Calculates population standard deviation.

  ## Examples

      iex> MeowNx.Utils.sd(Nx.tensor([2, 4]))
      #Nx.Tensor<
        f32
        1.0
      >
  """
  defn sd(t) do
    mean = Nx.mean(t)

    t
    |> Nx.subtract(mean)
    |> Nx.power(2)
    |> Nx.mean()
    |> Nx.sqrt()
  end

  @doc """
  Calculates entropy of values in the given tensor.

  That this function works with exact values. Sometimes different
  values belong to the same group, in those cases you need to
  preprocess the tensor beforehand. For example, when working with
  real numbers, you most likely want to round them, so they are
  compared with a specific precision.

  Note that this function uses natural logarithm.

  ## Examples

      iex> MeowNx.Utils.entropy(Nx.tensor([1, 1]))
      #Nx.Tensor<
        f32
        -0.0
      >

      iex> MeowNx.Utils.entropy(Nx.tensor([0.2, 0.22]))
      #Nx.Tensor<
        f32
        0.6931471824645996
      >

      iex> MeowNx.Utils.entropy(Nx.tensor([2, 1, 3, 1, 2, 1]))
      #Nx.Tensor<
        f32
        1.011404275894165
      >
  """
  defn entropy(t) do
    {n} = Nx.shape(t)

    sorted = Nx.sort(t)

    # A mask with a single 1 in every group of equal values,
    # computed by placing 1 where an element differs from its successor
    representative_mask =
      Nx.concatenate([
        Nx.not_equal(sorted[0..-2//1], sorted[1..-1//1]),
        Nx.tensor([1])
      ])

    # Calculate frequency for every element
    prob =
      Nx.equal(
        Nx.reshape(sorted, {n, 1}),
        Nx.reshape(sorted, {1, n})
      )
      |> Nx.sum(axes: [0])
      |> Nx.divide(n)

    prob
    |> Nx.log()
    |> Nx.multiply(prob)
    # Take the sum, but include probability for every unique value just once
    |> Nx.dot(representative_mask)
    |> Nx.negate()
  end

  @doc """
  Calculates a square of Euclidean distance for every
  pair of rows in the given 2-dimensional tensor.

  See https://stackoverflow.com/a/37040451

  ## Examples

      iex> t = Nx.tensor([
      ...>   [0, 0, 0],
      ...>   [1, 1, 1],
      ...>   [1, 2, -1]
      ...> ])
      iex> MeowNx.Utils.pairwise_squared_distance(t)
      #Nx.Tensor<
        s64[3][3]
        [
          [0, 3, 6],
          [3, 0, 5],
          [6, 5, 0]
        ]
      >
  """
  defn pairwise_squared_distance(t) do
    r =
      t
      |> Nx.multiply(t)
      |> Nx.sum(axes: [1])
      |> Nx.reshape({:auto, 1})

    result = r - 2 * Nx.dot(t, Nx.transpose(t)) + Nx.transpose(r)

    # Make sure there are no negative values due to precision errors
    Nx.max(result, 0)
  end

  @doc """
  Sorts permutations along the given axis.

  Each sorted sequence must be a permuation of indices and therefore
  it already includes the order information, which means that argsort
  can be computed in linear time.

  This gives the same value as `Nx.argsort/2` with `:axis`, however
  it is more efficient by levaraging the outlined properties.

  ## Examples

      iex> MeowNx.Utils.permutation_argsort(Nx.tensor([3, 1, 0, 2]), axis: 0)
      #Nx.Tensor<
        s64[4]
        [2, 1, 3, 0]
      >
  """
  defn permutation_argsort(permutations, opts \\ []) do
    opts = keyword!(opts, [:axis])
    axis = opts[:axis]

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

      iex> MeowNx.Utils.shift(Nx.iota({4}), 2)
      #Nx.Tensor<
        s64[4]
        [2, 3, 0, 1]
      >

      iex> MeowNx.Utils.shift(Nx.iota({4}), -1)
      #Nx.Tensor<
        s64[4]
        [1, 2, 3, 0]
      >

      iex> MeowNx.Utils.shift(Nx.iota({3, 3}), Nx.tensor([-1, 0, 1]), axis: 1)
      #Nx.Tensor<
        s64[3][3]
        [
          [1, 2, 0],
          [3, 4, 5],
          [8, 6, 7]
        ]
      >

      iex> MeowNx.Utils.shift(Nx.iota({2, 2, 2}), Nx.tensor([[1, 0], [0, 1]]), axis: 0)
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
    axis = opts[:axis]

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
    axis_idx = Nx.axis_index(tensor, axis)

    unless Nx.Type.integer?(offsets_type) do
      raise ArgumentError, "offsets must be an integer tensor, got #{inspect(offsets_type)}"
    end

    expected_offsets_shape = Tuple.delete_at(shape, axis_idx)

    unless offsets_shape == expected_offsets_shape do
      raise ArgumentError,
            "expected offsets to have shape #{inspect(expected_offsets_shape)}, got: #{inspect(offsets_shape)}"
    end
  end

  @doc """
  Asserts `left` has same shape as `right`.
  """
  defn assert_shape!(left, right) do
    transform({left, right}, fn {left, right} ->
      left_shape = Nx.shape(left)
      right_shape = Nx.shape(right)

      unless Elixir.Kernel.==(left_shape, right_shape) do
        raise ArgumentError,
              "expected tensor shapes to match, but got #{inspect(left_shape)} and #{inspect(right_shape)}"
      end
    end)
  end

  # Macros for use in defn

  @doc """
  Normalizes the given size with respect to the base tensor.

  The size may be either:

    * integer - an absolute size

    * float - a relative size, fraction of the base size

  The base size is taken from the first dimension of the
  given tensor.

  ## Options

    * `:limit_to_base` - enforces that the resulting size
      must not exceed the base size
  """
  defmacro resolve_n(n, base_t, opts \\ []) do
    quote bind_quoted: [n: n, base_t: base_t, opts: opts] do
      base_n = base_t |> Nx.shape() |> elem(0)

      Nx.Defn.Kernel.transform({n, base_n}, fn {n, base_n} ->
        MeowNx.Utils.do_resolve_n(n, base_n, opts)
      end)
    end
  end

  @doc false
  def do_resolve_n(n, base_n, opts) when is_float(n) do
    n = round(base_n * n)
    validate_n!(n, base_n, opts)
    n
  end

  def do_resolve_n(n, base_n, opts) when is_integer(n) do
    validate_n!(n, base_n, opts)
    n
  end

  defp validate_n!(n, base_n, opts) do
    if n < 0 do
      raise ArgumentError, "expected size to be a positive number, but resolved to: #{n}"
    end

    if opts[:limit_to_base] && n > base_n do
      raise ArgumentError, "expected size to not exceed the base size, but #{n} > #{base_n}"
    end
  end
end
