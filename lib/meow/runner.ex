defmodule Meow.Runner do
  @moduledoc """
  A module responsible for running an evolutionary
  algorithm, as defined by `Meow.Model`.
  """

  alias Meow.{Population, Pipeline, Model}

  @doc """
  Iteratively transforms the population according to
  the given model until the population is terminated.
  """
  @spec run(Model.t()) :: Population.t()
  def run(model) do
    genomes = model.initializer.()
    population = %Population{genomes: genomes, fitness: nil, generation: 1}
    ctx = %{evaluate: model.evaluate}

    # TODO: support multiple pipelines (populations)
    [pipeline] = model.pipelines

    run_population(population, pipeline, ctx)
  end

  defp run_population(population, pipeline, ctx) do
    population = Pipeline.apply(population, pipeline, ctx)

    if population.terminated do
      population
    else
      population
      |> Map.update!(:generation, &(&1 + 1))
      |> run_population(pipeline, ctx)
    end
  end
end
