defmodule MeowNx.Permutation do
  @moduledoc """
  Numerical implementations of common evolutionary operations for
  permutations without repetitions.
  """

  import Nx.Defn

  alias MeowNx.Utils

  # Each individual represented as a permutation of numbers starting
  # at 0. When applying evolutionary operations it is critical that
  # the resulting individuals are valid permuations, specifically,
  # that we don't introduce duplicate numbers.
  #
  # The primary idea driving the implementations is that we can work
  # on positions (indices), rather than the elements. Let's consider
  # the following permutation of elements
  #
  #     2 0 3 1
  #
  # In this sequence, the index is the position and the value is the
  # element at that position. We can view this as `position -> element`
  # mapping
  #
  #     0 -> 2, 1 -> 0, 2 -> 3, 3 -> 1
  #
  # Since both positions and elements use the same unique numbers, we
  # can cleanly reverse the mapping to `element -> position`, which
  # is represented by the following sequence
  #
  #     1 3 0 2
  #
  # In this sequence, the index is the element and the value is its
  # position in the original permutation.
  #
  # Note that translating between these representations is equivalent
  # to argsort, though it can be done in linear time.
  #
  # ## One-point crossover
  #
  # To give a better idea of how the positions domain works, let's
  # consider one-point crossover (adopted for permutations). We have
  # the following pair of individuals:
  #
  #     2 0 3 1
  #     1 2 3 0
  #
  # For this example we can assume the cut is in the middle. This
  # means that we want to copy the first two elements from parents to
  # offsprings, then we want to add the remaining elements following
  # their order in the other parent.
  #
  # In the first step, we translate permutations to positions, as
  # outlined in the previous section
  #
  #     1 3 0 2
  #     3 0 1 2
  #
  # Now, remember that indices correspond to permutation elements. We
  # want to keep first two elements unchanged, so we fix the first
  # two positions, that is 0 and 1
  #
  #     1 * 0 *
  #     * 0 1 *
  #
  # Next, for the remaining elements, we take their positions from
  # the other parent. We increase those positions by 10, so that all
  # values are unique, and the relative order is preserved
  #
  #      1 10  0 12
  #     11  0  1 12
  #
  # This gives us improper positions, which means that the values are
  # not valid positions, but the relative order is fine. Fortunately,
  # we can convert improper positions back to elements using argsort
  #
  #     2 0 1 3
  #     1 2 0 3
  #
  # This is where the magic happens. Since we increased the positions
  # of elements taken from the other parent, those elements end up at
  # the end (in the correct order), while the first two elements stay
  # untouched.
  #
  # In the above operation there are two blocks, left and right. The
  # important characteristic is that the elements within the left
  # block are kept as is, while the remaining ones are reordered to
  # match the other parent. This behaviour can be used to implement
  # other crossover types. We would first move the elements we want
  # to fix to the first block and the rest to the second block, then
  # we would apply this operation, finally we would move the elements
  # back by inverting the first step.

  @doc """
  Generates a population, where each genome is a random permutation
  of numbers from `0` to `length - 1`.

  ## Options

    * `:n` - the number of individuals to generate. Required.

    * `:length` - the length of a single genome. Required.
  """
  defn init_random(opts \\ []) do
    opts = keyword!(opts, [:n, :length])
    n = opts[:n]
    length = opts[:length]

    Nx.random_uniform({n, length})
    |> Nx.argsort(axis: 1)
    |> Nx.as_type({:u, 16})
  end

  @doc """
  Performs single-point crossover adopted for permutations.

  For parent genomes $x$ and $y$, this operation chooses a random
  split point. All genes $x_i$, $y_i$ until that split point are
  copied to the offsprings. Then, the missing genes are copied from
  the other parent keeping their relative order.

  ## References

    * [Genetic Algorithms for Shop Scheduling Problems: A Survey](https://www.researchgate.net/publication/230724890_GENETIC_ALGORITHMS_FOR_SHOP_SCHEDULING_PROBLEMS_A_SURVEY), Fig. 8.
  """
  defn crossover_single_point(genomes) do
    {n, length} = Nx.shape(genomes)
    half_n = transform(n, &div(&1, 2))

    positions = permutations_to_positions(genomes)
    split_position = Nx.random_uniform({half_n, 1}, 1, length) |> Utils.duplicate_rows()

    positions_single_point(positions, positions, split_position)
  end

  @doc """
  Performs order crossover (OX).

  For parent genomes $x$ and $y$, this operation chooses two random
  split points. All genes $x_i$, $y_i$ between those split points are
  copied to the offsprings. Then, the missing genes are copied from
  the other parent keeping their relative order, going from the second
  split point.

  Note that OX is designed for cyclic permutations, so for non-cyclic
  permutations LOX (`crossover_linear_order/1`) is a better fit.

  ## References

    * [Genetic Algorithms for Shop Scheduling Problems: A Survey](https://www.researchgate.net/publication/230724890_GENETIC_ALGORITHMS_FOR_SHOP_SCHEDULING_PROBLEMS_A_SURVEY), Fig. 9.
  """
  defn crossover_order(genomes) do
    {offset, block_length} = random_genome_blocks(genomes, paired: true)

    positions = permutations_to_positions(genomes)
    shifted_positions = shift_positions(positions, -offset)

    positions_single_point(
      shifted_positions,
      # For the remaining elments we want to inherit the relative
      # order from the other parent, but starting from the second
      # crossover point. To do so we shift the parent elements
      # further to the left by the block length
      shift_positions(shifted_positions, -block_length),
      block_length
    )
    |> Utils.shift(Nx.reshape(offset, {:auto}), axis: 1)
  end

  @doc """
  Performs position based crossover (PBX).

  This operation chooses a number of random positions and copies genes
  at those positions to the offsprings. Then, the missing genes are
  copied from the other parent keeping their relative order.

  Order based crossover (OBX) is another common operation, however it
  is effectively the same as PBX.

  ## References

    * [Genetic Algorithms for Shop Scheduling Problems: A Survey](https://www.researchgate.net/publication/230724890_GENETIC_ALGORITHMS_FOR_SHOP_SCHEDULING_PROBLEMS_A_SURVEY), Fig. 12.
    * [Crossover operators for permutations equivalence between position and order-based crossover](https://www.researchgate.net/publication/220245134_Crossover_operators_for_permutations_equivalence_between_position_and_order-based_crossover)
  """
  defn crossover_position_based(genomes) do
    {n, length} = Nx.shape(genomes)
    half_n = transform(n, &div(&1, 2))

    fix_position? = Nx.random_uniform({half_n, length}, 0, 2) |> Utils.duplicate_rows()
    split_position = Nx.sum(fix_position?, axes: [1], keep_axes: true)

    mapping =
      fix_position?
      |> Nx.iota(axis: 1)
      |> Nx.add(Nx.negate(fix_position?) * length)
      |> relative_positions_to_permutations()

    mapped_single_point(genomes, mapping, split_position)
  end

  @doc """
  Performs linear order crossover (LOX).

  This is a modified version of `crossover_order/1`. Similarly, two
  split points are choosen and genes between those points are copied
  directly to the offspring. Then, the missing genes are copied from
  the other parent starting from the first position (as opposed to OX,
  where we start from the second split point).

  Note that that this operation was later reintroduced under the name
  non-wrapping order crossover (NWOX).

  ## References

    * [Genetic Algorithms for Shop Scheduling Problems: A Survey](https://www.researchgate.net/publication/230724890_GENETIC_ALGORITHMS_FOR_SHOP_SCHEDULING_PROBLEMS_A_SURVEY), Fig. 10.
    * [Non-Wrapping Order Crossover: An Order Preserving Crossover Operator that Respects Absolute Position](https://www.researchgate.net/publication/220739642_Non-wrapping_order_crossover_An_order_preserving_crossover_operator_that_respects_absolute_position)
  """
  defn crossover_linear_order(genomes) do
    {offset, block_length} = random_genome_blocks(genomes, paired: true)

    # A random block divides genome into three parts A B C (where B
    # is the random block). We want to rearrange the genes into parts
    # B A C, so that we can fix genes in B. We do this rearrangement
    # by generating an index mapping

    idx = Nx.iota(genomes, axis: 1)

    mapping =
      idx + (idx < block_length) * offset -
        (block_length <= idx and idx < offset + block_length) * block_length

    mapped_single_point(genomes, mapping, block_length)
  end

  @doc """
  Performs inversion mutation.

  This operation chooses two random points in the genome and reverses
  all elements between these points.

  ## Options

    * `:probability` - probability of an individual being mutated.
      Required

  ## References

    * [Genetic Algorithms for Shop Scheduling Problems: A Survey](https://www.researchgate.net/publication/230724890_GENETIC_ALGORITHMS_FOR_SHOP_SCHEDULING_PROBLEMS_A_SURVEY), Fig. 15.
  """
  defn mutation_inversion(genomes, opts \\ []) do
    opts = keyword!(opts, [:probability])
    probability = opts[:probability]

    {offset, block_length} = random_genome_blocks(genomes, paired: false)

    a = offset
    b = offset + block_length - 1

    idx = Nx.iota(genomes, axis: 1)
    block? = a <= idx and idx <= b
    mapping = Nx.select(block?, b - (idx - a), idx)
    mutated = Nx.take_along_axis(genomes, mapping, axis: 1)

    incorporate_mutated(genomes, mutated, probability)
  end

  @doc """
  Performs swap mutation.

  This operation swaps two random elements in the genome.

  Note that this operation is also referred to as exchange mutation
  or interchange mutation.

  ## Options

    * `:probability` - probability of an individual being mutated.
      Required

  ## References

    * [Genetic Algorithms for Shop Scheduling Problems: A Survey](https://www.researchgate.net/publication/230724890_GENETIC_ALGORITHMS_FOR_SHOP_SCHEDULING_PROBLEMS_A_SURVEY), Fig. 14.
  """
  defn mutation_swap(genomes, opts \\ []) do
    opts = keyword!(opts, [:probability])
    probability = opts[:probability]

    {n, length} = Nx.shape(genomes)

    # Randomly generate two distinct positions
    swap_position1 = Nx.random_uniform({n}, 0, length)
    swap_position2 = Nx.random_uniform({n}, 0, length - 1)
    swap_position2 = swap_position2 + (swap_position2 >= swap_position1)
    swap_positions = Nx.stack([swap_position1, swap_position2], axis: -1)

    indices = Nx.stack([Nx.iota({n, 2}, axis: 0), swap_positions], axis: -1)
    values = Nx.gather(genomes, indices)
    swapped_values = Nx.reverse(values, axes: [1])
    diff = swapped_values - values

    mutated =
      Nx.indexed_add(
        genomes,
        Nx.reshape(indices, {:auto, 2}),
        Nx.reshape(diff, {:auto})
      )

    incorporate_mutated(genomes, mutated, probability)
  end

  defnp incorporate_mutated(genomes, mutated_genomes, probability) do
    {n, length} = Nx.shape(genomes)

    mutate? = Nx.random_uniform({n, 1}) |> Nx.less(probability)

    mutate?
    |> Nx.broadcast({n, length})
    |> Nx.select(mutated_genomes, genomes)
  end

  defnp positions_single_point(positions, parent_positions, split_position) do
    {_n, length} = Nx.shape(positions)

    # For elements until the split point we keep the same positions.
    # For the remaining elements we copy their positions from the
    # other parent and increase them by `length`. This way when we
    # do argsort, those elements end up at the end, but their relative
    # order is preserved.
    Nx.select(
      positions < split_position,
      parent_positions,
      parent_positions |> MeowNx.Utils.swap_adjacent_rows() |> Nx.add(length)
    )
    |> relative_positions_to_permutations()
  end

  defnp mapped_single_point(genomes, mapping, split_position) do
    reverse_mapping = permutations_to_positions(mapping)

    mapped_genomes = Nx.take_along_axis(genomes, mapping, axis: 1)
    mapped_positions = permutations_to_positions(mapped_genomes)

    positions = permutations_to_positions(genomes)

    # For the other parent we want to consider the original order
    positions_single_point(mapped_positions, positions, split_position)
    |> Nx.take_along_axis(reverse_mapping, axis: 1)
  end

  defnp random_genome_blocks(genomes, opts \\ []) do
    opts = keyword!(opts, paired: false)

    transform({genomes, opts[:paired]}, fn
      {genomes, false} ->
        {n, length} = Nx.shape(genomes)
        random_blocks(n: n, length: length)

      {genomes, true} ->
        {n, length} = Nx.shape(genomes)
        {offset, block_length} = random_blocks(n: div(n, 2), length: length)
        {Utils.duplicate_rows(offset), Utils.duplicate_rows(block_length)}
    end)
  end

  defnp random_blocks(opts \\ []) do
    n = opts[:n]
    length = opts[:length]

    idx1 = Nx.random_uniform({n, 1}, 0, length)
    idx2 = Nx.random_uniform({n, 1}, 0, length)

    a = Nx.min(idx1, idx2)
    b = Nx.max(idx1, idx2)

    offset = a
    block_length = b - a + 1

    {offset, block_length}
  end

  defnp shift_positions(positions, offset) do
    {_, length} = Nx.shape(positions)
    Nx.remainder(positions + offset + length, length)
  end

  defnp permutations_to_positions(permutations) do
    Utils.permutation_argsort(permutations, axis: 1)
  end

  defnp relative_positions_to_permutations(relative_positions) do
    relative_positions
    |> Nx.argsort(axis: 1)
    |> Nx.as_type(Nx.type(relative_positions))
  end
end
