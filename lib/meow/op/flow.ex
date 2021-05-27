defmodule Meow.Op.Flow do
  @moduledoc """
  Core operations relevant to pipeline flow.
  """

  alias Meow.{Op, Pipeline, Population}

  @doc """
  Builds an operation that introduces branching into the pipeline.

  The operation splits population into a number of populations,
  each of which is then passed through a corresponding pipeline
  from the given list. Finally all populations are joined back
  into a single population with the given join function.
  """
  @spec split_join(
          (Population.t() -> list(Population.t())),
          list(Pipeline.t()),
          (list(Population.t()) -> Population.t())
        ) :: Op.t()
  def split_join(split_fun, pipelines, join_fun) do
    requires_fitness = Enum.any?(pipelines, fn %{ops: [op | _]} -> op.requires_fitness end)

    %Op{
      name: "Flow: split join",
      # This operation itself doesn't require fitness,
      # but if any pipeline does, then we eagerly do so as well.
      requires_fitness: requires_fitness,
      # This operation itself doesn't invalidate fitness,
      # it just joins results of the underlying pipelines.
      invalidates_fitness: false,
      impl: fn population, ctx ->
        population
        |> split_fun.()
        |> Enum.zip(pipelines)
        |> Enum.map(fn {population, pipeline} ->
          Pipeline.apply(population, pipeline, ctx)
        end)
        |> join_fun.()
      end
    }
  end

  @doc """
  Builds an operation that introduces conditional flow
  into the pipeline.

  The operation evaluates the given predicate function
  and passes the population through either of the given
  pipelines.
  """
  @spec if((Population.t() -> boolean()), Pipeline.t(), Pipeline.t()) :: Op.t()
  def if(pred_fun, on_true_pipeline, on_false_pipeline) do
    %Op{
      name: "Flow: if",
      requires_fitness: false,
      invalidates_fitness: false,
      impl: fn population, ctx ->
        pipeline = if(pred_fun.(population), do: on_true_pipeline, else: on_false_pipeline)
        Pipeline.apply(population, pipeline, ctx)
      end
    }
  end
end
