defmodule Meow.Op.Flow do
  alias Meow.{Op, Pipeline}

  def split_merge(split_fun, pipelines, merge_fun) do
    requires_fitness = Enum.any?(pipelines, fn %{ops: [op | _]} -> op.requires_fitness end)

    %Op{
      name: "Flow: split merge",
      # This operation itself doesn't require fitness,
      # but if any pipeline does, then we eagerly do so as well.
      requires_fitness: requires_fitness,
      # This operation itself doesn't invalidate fitness,
      # it just merges results of the underlying pipelines.
      invalidates_fitness: false,
      impl: fn population, ctx ->
        population
        |> split_fun.()
        |> Enum.zip(pipelines)
        |> Enum.map(fn {population, pipeline} ->
          Pipeline.apply(population, pipeline, ctx)
        end)
        |> merge_fun.()
      end
    }
  end

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
