defmodule Meow.Op.Context do
  @moduledoc """
  Additional information available to operations
  that is not strictly related to the transformed
  population.
  """

  defstruct [:evaluate, :population_pids, :global_opts]

  alias Meow.Model

  @type t :: %__MODULE__{
          evaluate: Model.evaluate(),
          population_pids: list(pid()),
          global_opts: keyword()
        }
end
