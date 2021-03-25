defmodule Meow.EvolutionSpec do
  alias Meow.{Individual, Population}

  @moduledoc """
  The behaviour for configuring evolutionary algorithm
  in respect to a specific optimisation problem.

  `Meow.EvolutionSpec` serves as an interface for the user to implement
  in order to run a concerete evolutionary algorithm
  against the optimisation problem of choice.

  ## Problem

  The optimisation problem is given by implementing the following
  functions: `generate/0`, `evaluate/1` and `terminate?/1`.
  A single solution (genome) may be represented however the user sees fit,
  as long as the evolutionary operators (like crossover and mutation)
  are implemented to work with the chosen representation.

  ## Algorithm

  All remaining functions allow for configuring the evolutionary algorithm.
  """

  # Problem definition

  @doc """
  Generates a random solution to the problem.
  """
  @callback generate() :: Individual.genome()

  @doc """
  Calculates an assessment of the given solution.

  Essentially, this is the function you are trying to optimise.
  Note that the algorithm tries to maximise this function,
  so make sure that higher values indicate a better solutoion.
  """
  @callback evaluate(Individual.genome()) :: Individual.fitness()

  @doc """
  Defines the termination criteria of the algorithm.

  An evolutionary algorithm is an iterative process
  and would run infinitely, so we have to define
  at which point it should finish (based on how long it runs
  or some population metrics).
  """
  @callback terminate?(Population.t()) :: boolean()

  # Algorithm definition

  @doc """
  Defines how solutions (genomes) are mutated.

  This opertion should introduce randomness,
  kinda like a new genetic material.
  """
  @callback mutate(Individual.genome()) :: Individual.genome()

  @doc """
  Defines how to choose a group of parents from the population.

  The choosen parents are then used for crossover.
  """
  @callback select_parents(Population.t()) :: list(Individual.t())

  @doc """
  Defines which individuals from the current population are kept for the next generation.
  """
  @callback select_survivors(Population.t()) :: list(Individual.t())

  @doc """
  Combines two solutions (genomes) into two new solutions.
  """
  @callback crossover(Individual.genome(), Individual.genome()) ::
              {Individual.genome(), Individual.genome()}
end
