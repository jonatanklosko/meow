defmodule Meow.Runner do
  alias Meow.{Population, Pipeline}

  def run(model) do
    genomes = model.initializer.()
    population = %Population{genomes: genomes, fitness: nil, generation: 1}

    # TODO: support multiple pipelines (populations)
    [pipeline] = model.pipelines

    run_population(population, pipeline, model)
  end

  defp run_population(population, pipeline, model) do
    population = Pipeline.apply(population, pipeline, model.evaluate)

    if population.terminated do
      population
    else
      population
      |> Map.update!(:generation, &(&1 + 1))
      |> run_population(pipeline, model)
    end
  end
end
