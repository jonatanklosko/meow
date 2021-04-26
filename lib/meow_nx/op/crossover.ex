defmodule MeowNx.Op.Crossover do
  import Nx.Defn
  alias Meow.Op

  def uniform(probability \\ 0.5) do
    opts = [probability: probability]

    %Op{
      name: "[Nx] Uniform crossover",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population ->
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
end
