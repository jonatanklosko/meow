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

  alias Meow.{Op, Population}

  @type t :: %__MODULE__{
          ops: list(Op.t())
        }

  @doc false
  # See `Meow.pipeline/1`
  def new(ops) do
    %__MODULE__{ops: ops}
  end

  @doc """
  Pipes `population` through `pipeline`.

  The result is a new transformed population.
  The `evaluate` function is used as necessary
  to ensure fitness is computed if needed.
  """
  @spec apply(Population.t(), t(), Op.Context.t()) :: Population.t()
  def apply(population, pipeline, ctx) do
    do_apply(population, pipeline.ops, ctx)
  end

  defp do_apply(%{terminated: true} = population, _ops, _ctx), do: population
  defp do_apply(population, [], _ctx), do: population

  defp do_apply(population, [op | ops], ctx) do
    population
    |> before_op_apply(op, ctx)
    |> Op.apply(op, ctx)
    |> after_op_apply(op, ctx)
    |> do_apply(ops, ctx)
  end

  defp before_op_apply(%{fitness: nil} = population, %{requires_fitness: true}, ctx) do
    fitness = ctx.evaluate.(population.genomes)
    %{population | fitness: fitness}
  end

  defp before_op_apply(population, _op, _ctx), do: population

  defp after_op_apply(population, %{invalidates_fitness: true}, _ctx) do
    %{population | fitness: nil}
  end

  defp after_op_apply(population, _op, _ctx), do: population
end
