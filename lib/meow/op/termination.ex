defmodule Meow.Op.Termination do
  @moduledoc """
  Core operations relevant to algorithm termination criteria.
  """

  alias Meow.Op

  @doc """
  Builds an operation that terminates the population
  if the given number of generations is reached.
  """
  @spec max_generations(non_neg_integer()) :: Op.t()
  def max_generations(generations) do
    %Op{
      name: "Termination: max generations",
      requires_fitness: false,
      invalidates_fitness: false,
      impl: fn population, _ctx ->
        if population.generation >= generations do
          %{population | terminated: true}
        else
          population
        end
      end
    }
  end
end
