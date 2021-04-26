defmodule Meow.Pipeline do
  defstruct [:ops]

  alias Meow.Op

  def new(ops) do
    %__MODULE__{ops: ops}
  end

  def apply(population, pipeline, evaluate) do
    do_apply(population, pipeline.ops, evaluate)
  end

  defp do_apply(%{terminated: true} = population, _ops, _evaluate), do: population
  defp do_apply(population, [], _evaluate), do: population

  defp do_apply(population, [op | ops], evaluate) do
    population
    |> before_op_apply(op, evaluate)
    |> Op.apply(op)
    |> after_op_apply(op, evaluate)
    |> do_apply(ops, evaluate)
  end

  defp before_op_apply(%{fitness: nil} = population, %{requires_fitness: true}, evaluate) do
    fitness = evaluate.(population.genomes)
    %{population | fitness: fitness}
  end

  defp before_op_apply(population, _op, _evaluate), do: population

  defp after_op_apply(population, %{invalidates_fitness: true}, _evaluate) do
    %{population | fitness: nil}
  end

  defp after_op_apply(population, _op, _evaluate), do: population
end
