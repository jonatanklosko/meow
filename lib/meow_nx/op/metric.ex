defmodule MeowNx.Op.Metric do
  @moduledoc """
  Metric operations backed by numerical definitions.

  This module provides a compatibility layer for `Meow`,
  while individual numerical definitions can be found
  in `MeowNx.Metric`.
  """

  alias Meow.Op
  alias MeowNx.Metric
  alias MeowNx.Utils

  @doc """
  Builds a metric operation loging the best individual.

  See `MeowNx.Metric.best_individual/2` for more details.
  """
  @spec best_individual() :: Op.t()
  def best_individual() do
    %Op{
      name: "Metric: best individual",
      requires_fitness: true,
      invalidates_fitness: false,
      impl: fn population, ctx ->
        {best_genome, best_fitness} =
          Nx.Defn.jit(
            &Metric.best_individual/2,
            [population.genomes, population.fitness],
            Utils.jit_opts(ctx)
          )

        best_individual = %{
          genome: best_genome,
          fitness: Nx.to_scalar(best_fitness),
          generation: population.generation
        }

        update_in(population.metrics, fn metrics ->
          Map.update(metrics, :best_individual, best_individual, fn individual ->
            Enum.max_by([individual, best_individual], & &1.fitness)
          end)
        end)
      end
    }
  end
end
