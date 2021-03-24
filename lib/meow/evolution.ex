defmodule Meow.Evolution do
  alias Meow.{Individual, Population}

  # TODO: these should be configured elsewhere (as opts to run?)
  @population_size 20
  @mutation_probability 0.1

  def run(spec) do
    initialize_population(spec)
    |> do_evaluate(spec)
    |> evolve(spec)
  end

  defp initialize_population(spec) do
    individuals =
      Stream.repeatedly(fn ->
        genome = spec.generate()
        %Individual{genome: genome}
      end)
      |> Enum.take(@population_size)

    %Population{individuals: individuals}
  end

  defp do_evaluate(population, spec) do
    individuals =
      Enum.map(population.individuals, fn
        %{fitness: nil} = individual ->
          fitness = spec.evaluate(individual.genome)
          %{individual | fitness: fitness}

        evaluated_individual ->
          evaluated_individual
      end)

    best_individual = Enum.max_by(individuals, & &1.fitness)

    improved? =
      population.best_individual_ever == nil or
        population.best_individual_ever.fitness <= best_individual.fitness

    %{
      population
      | individuals: individuals,
        best_individual_ever:
          if(improved?, do: best_individual, else: population.best_individual_ever)
    }
  end

  defp evolve(population, spec) do
    if spec.terminate?(population) do
      population
    else
      parents = spec.select_parents(population)
      # TODO: we should keep a configured percentage of population (survivors)
      children = do_crossover(parents, spec)
      new_individuals = do_mutation(children, spec)

      new_population = %{
        population
        | individuals: new_individuals,
          generation: population.generation + 1,
          number_of_fitness_evals:
            population.number_of_fitness_evals + length(population.individuals)
      }

      new_population = do_evaluate(new_population, spec)

      evolve(new_population, spec)
    end
  end

  defp do_mutation(individuals, spec) do
    Enum.map(individuals, fn individual ->
      if :rand.uniform() < @mutation_probability do
        new_genome = spec.mutate(individual.genome)
        %{individual | genome: new_genome, fitness: nil}
      else
        individual
      end
    end)
  end

  defp do_crossover(parents, spec) do
    parents
    |> Enum.chunk_every(2, 2, :discard)
    |> Enum.flat_map(fn [parent1, parent2] ->
      {child1_genome, child2_genome} = spec.crossover(parent1.genome, parent2.genome)
      [%Individual{genome: child1_genome}, %Individual{genome: child2_genome}]
    end)
  end
end
