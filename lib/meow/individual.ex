defmodule Meow.Individual do
  @moduledoc """
  Represents a single solution to an optimisation problem.

  The solution representation is encoded in the `genome` field.
  """

  defstruct [:genome, :fitness]

  @type t :: %__MODULE__{
          genome: genome(),
          fitness: fitness() | nil
        }

  @typedoc """
  The actual representation of the solution.

  This type is opaque treated as opaque and its definition
  is left up to the user.
  """
  @type genome :: term()

  @typedoc """
  A numeric assesment of the solution quality.

  How this value is calculated is directly determined
  by the problem at hand. Higher `fitness` indicates
  a better solution.
  """
  @type fitness :: number()
end
