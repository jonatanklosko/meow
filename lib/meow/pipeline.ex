defmodule Meow.Pipeline do
  @moduledoc """
  Definition of en evolutionary pipeline.

  A single pipeline represents a sequence of steps
  that a single population goes through in the given
  evolutionary algorithm. Each step is of type `Meow.Op`
  and transforms the population. Consequently the pipeline
  takes a population in and produces a transformed
  population out.
  """

  defstruct [:ops]

  alias Meow.{Op, Population, Model}

  @type t :: %__MODULE__{
          ops: list(Op.t())
        }

  @doc """
  Builds a new pipeline from a list of operations.
  """
  @spec new(list(Op.t())) :: t()
  def new(ops) do
    %__MODULE__{ops: ops}
  end

  @doc """
  Pipes `population` through `pipeline`.

  The result is a new transformed population.
  The `evaluate` function is used as necessary
  to ensure fitness is computed if needed.
  """
  @spec apply(Population.t(), t(), Model.evaluate()) :: Population.t()
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
