defmodule MeowNx.Op.Crossover do
  import Nx.Defn
  alias Meow.Op

  def uniform(probability \\ 0.5) do
    opts = [probability: probability]

    %Op{
      name: "[Nx] Uniform crossover",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, _ctx ->
        Op.map_genomes(population, fn genomes ->
          # TODO: make compiler (and generally other options)
          # configurable globally for the model
          Nx.Defn.jit(&uniform_impl(&1, opts), [genomes], compiler: EXLA)
        end)
      end
    }
  end

  defnp uniform_impl(parents, opts \\ []) do
    probability = opts[:probability]

    {n, length} = Nx.shape(parents)
    half_n = transform(n, &div(&1, 2))

    upper_sel = Nx.random_uniform({half_n, length}) |> Nx.greater(probability)
    lower_sel = Nx.reverse(upper_sel, axes: [0])
    # Generate a 0/1 matrix symmetric along the first axis
    selection = Nx.concatenate([upper_sel, lower_sel])

    Nx.select(selection, parents, Nx.reverse(parents, axes: [0]))
  end

  def single_point() do
    %Op{
      name: "[Nx] Single point crossover",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, _ctx ->
        Op.map_genomes(population, fn genomes ->
          # TODO: make compiler (and generally other options)
          # configurable globally for the model
          Nx.Defn.jit(&single_point_impl(&1), [genomes], compiler: EXLA)
        end)
      end
    }
  end

  defnp single_point_impl(parents, _opts \\ []) do
    {n, length} = Nx.shape(parents)
    half_n = transform(n, &div(&1, 2))

    slice_idx = transform(length, fn length -> :rand.uniform(length - 1) end)
    left = parents[[0..(n - 1), 0..(slice_idx - 1)]]
    right = parents[[0..(n - 1), slice_idx..(length - 1)]]

    left = left
      |> Nx.reshape({half_n, 2, slice_idx})
      |> Nx.reverse(axes: [1])
      |> Nx.reshape({n, slice_idx})

    Nx.concatenate([left, right], axis: 1)
  end
end
