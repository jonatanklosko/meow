defmodule Meow.Op.Context do
  @moduledoc """
  Additional information available to operations
  that is not strictly related to the transformed
  population.
  """

  defstruct [:evaluate, :population_pids]

  alias Meow.Algorithm

  @type t :: %__MODULE__{
          evaluate: Algorithm.evaluate(),
          population_pids: list(pid())
        }
end
