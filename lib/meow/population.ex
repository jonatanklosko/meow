defmodule Meow.Population do
  @moduledoc """
  Represents a group of individuals that evolve over time.

  This struct can be thought of as evolution snapshot at specific
  point in time. It contains the list of currently living individuals
  as well as information about the evolution progress.
  """

  defstruct individuals: [],
            generation: 0,
            number_of_fitness_evals: 0,
            best_individual_ever: nil

  @type t :: %__MODULE__{
          individuals: list(Individual.t()),
          generation: non_neg_integer(),
          number_of_fitness_evals: non_neg_integer(),
          best_individual_ever: Individual.t() | nil
        }
end
