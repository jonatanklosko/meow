defmodule Meow.Evolution do
  @moduledoc """
  The entrypoint for running your algorithm.

  Evolution consists of the following steps:

  1. Randomly initialize the population
  2. Evolve the population until the termination criteria is satisfied
     1. Select parents and breed new individuals
     2. Possibly apply mutation to some individuals
     3. Form the new population (children and selected survivors)
     4. Evaluate the new population
  """

  alias Meow.{Individual, Population}

  # TODO: these should be configured elsewhere (as opts to run?)
  @population_size 20
  @mutation_probability 0.1

  @doc """
  Runs an evolutionary algorithm according to the given specification.

  The first argument must be a module implementing the `Meow.EvolutionSpec`
  behaviour, which defines the optimisation problem, as well as the
  algorithm details.
  """
  @spec run(atom()) :: Population.t()
  def run(spec) when is_atom(spec) do
    initialize_population(spec)
    |> evaluate_population(spec)
    |> evolve_population(spec)
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

  defp evaluate_population(population, spec) do
    {evaluated_individuals, number_of_evals} =
      Enum.map_reduce(population.individuals, 0, fn
        %{fitness: nil} = individual, number_of_evals ->
          fitness = spec.evaluate(individual.genome)
          individual = %{individual | fitness: fitness}
          {individual, number_of_evals + 1}

        individual, number_of_evals ->
          {individual, number_of_evals}
      end)

    best_individual = Enum.max_by(evaluated_individuals, & &1.fitness)

    best_individual_ever =
      if population.best_individual_ever do
        Enum.max_by([population.best_individual_ever, best_individual], & &1.fitness)
      else
        best_individual
      end

    %{
      population
      | individuals: evaluated_individuals,
        best_individual_ever: best_individual_ever,
        number_of_fitness_evals: population.number_of_fitness_evals + number_of_evals
    }
  end

  defp evolve_population(population, spec) do
    if spec.terminate?(population) do
      population
    else
      parents = spec.select_parents(population)
      survivors = spec.select_survivors(population)
      children = crossover(parents, spec)
      new_individuals = children ++ survivors

      new_individuals = mutation(new_individuals, spec)

      new_population = %{
        population
        | individuals: new_individuals,
          generation: population.generation + 1
      }

      new_population
      |> evaluate_population(spec)
      |> evolve_population(spec)
    end
  end

  defp mutation(individuals, spec) do
    Enum.map(individuals, fn individual ->
      if :rand.uniform() < @mutation_probability do
        new_genome = spec.mutate(individual.genome)
        %{individual | genome: new_genome, fitness: nil}
      else
        individual
      end
    end)
  end

  defp crossover(parents, spec) do
    parents
    |> Enum.chunk_every(2, 2, :discard)
    |> Enum.flat_map(fn [parent1, parent2] ->
      {child1_genome, child2_genome} = spec.crossover(parent1.genome, parent2.genome)
      [%Individual{genome: child1_genome}, %Individual{genome: child2_genome}]
    end)
  end
end
