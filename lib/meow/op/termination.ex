defmodule Meow.Op.Termination do
  alias Meow.Op

  def max_generations(n) do
    %Op{
      name: "Termination: max generations",
      requires_fitness: false,
      invalidates_fitness: false,
      impl: fn population ->
        if population.generation >= n do
          %{population | terminated: true}
        else
          population
        end
      end
    }
  end
end
