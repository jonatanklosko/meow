defmodule Meow.Ops do
  @moduledoc """
  Core operations universal for all representation types.
  """

  alias Meow.{Op, Pipeline, Population}

  @doc """
  Builds an operation that terminates the population
  if the given number of generations is reached.
  """
  @doc type: :termination
  @spec max_generations(non_neg_integer()) :: Op.t()
  def max_generations(generations) do
    %Op{
      name: "Termination: max generations",
      requires_fitness: false,
      invalidates_fitness: false,
      in_representations: :any,
      impl: fn population, _ctx ->
        if population.generation >= generations do
          %{population | terminated: true}
        else
          population
        end
      end
    }
  end

  @doc """
  Builds an operation that introduces branching into the pipeline.

  The operation splits population into a number of populations,
  each of which is then passed through a corresponding pipeline
  from the given list. Finally all populations are joined back
  into a single population with the given join function.
  """
  @doc type: :flow
  @spec split_join(
          (Population.t() -> list(Population.t())),
          list(Pipeline.t()),
          (list(Population.t()) -> Population.t())
        ) :: Op.t()
  def split_join(split_fun, pipelines, join_fun) do
    requires_fitness = Enum.any?(pipelines, fn %{ops: [op | _]} -> op.requires_fitness end)
    in_representations = common_in_representations(pipelines)
    out_representation = common_out_representation(pipelines)

    %Op{
      name: "Flow: split join",
      # This operation itself doesn't require fitness,
      # but if any pipeline does, then we eagerly do so as well.
      requires_fitness: requires_fitness,
      # This operation itself doesn't invalidate fitness,
      # it just joins results of the underlying pipelines.
      invalidates_fitness: false,
      in_representations: in_representations,
      out_representation: out_representation,
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

  defp common_in_representations(pipelines) do
    pipelines
    |> Enum.map(fn %{ops: [op | _]} -> MapSet.new(op.in_representations) end)
    |> Enum.reduce(&MapSet.intersection/2)
    |> MapSet.to_list()
  end

  defp common_out_representation(pipelines) do
    pipelines
    |> Enum.map(fn pipeline -> List.last(pipeline.ops).out_representation end)
    |> Enum.uniq()
    |> List.delete(:same)
    |> case do
      [] ->
        :same

      [out_representation] ->
        out_representation

      representations ->
        raise ArgumentError,
              "pipelines must have the same output representation, but got: #{inspect(representations)}"
    end
  end

  @doc """
  Builds an operation that introduces conditional flow
  into the pipeline.

  The operation evaluates the given predicate function
  and passes the population through either of the given
  pipelines.
  """
  @doc type: :flow
  @spec if((Population.t() -> boolean()), Pipeline.t(), Pipeline.t()) :: Op.t()
  def if(pred_fun, on_true_pipeline, on_false_pipeline) do
    pipelines = [on_true_pipeline, on_false_pipeline]
    in_representations = common_in_representations(pipelines)
    out_representation = common_out_representation(pipelines)

    %Op{
      name: "Flow: if",
      requires_fitness: false,
      invalidates_fitness: false,
      in_representations: in_representations,
      out_representation: out_representation,
      impl: fn population, ctx ->
        pipeline = if(pred_fun.(population), do: on_true_pipeline, else: on_false_pipeline)
        Pipeline.apply(population, pipeline, ctx)
      end
    }
  end

  @doc """
  Builds an emigration operation.

  Emigration involves selecting a number of interesting
  individuals and sending them to other populations.
  The group of emigrants is determined by the given selection
  operation and distributed according to the given topology.

  ## Options

    * `:interval` - the interval (number of generations)
      determining how often emigration takes place. Defaults to 1.

    * `:number_of_targets` - the number of neighbours to send
      the selected individuals to. Must be either a number
      or a range, in which case the number is randomly
      drawn every time. Defaults to 1.
  """
  @doc type: :multi
  @spec emigrate(Op.t(), Topology.topology_fun(), keyword()) :: Op.t()
  def emigrate(selection_op, topology_fun, opts \\ []) do
    interval = Keyword.get(opts, :interval, 1)

    targets_range =
      case Keyword.get(opts, :number_of_targets, 1) do
        n when is_integer(n) ->
          n..n

        min..max ->
          min..max

        other ->
          raise ArgumentError,
                "expected :number_of_targets to be either a number or a range, got: #{inspect(other)}"
      end

    %Op{
      name: "Multi-population: emigration",
      requires_fitness: false,
      invalidates_fitness: false,
      in_representations: :any,
      impl: fn population, ctx ->
        if length(ctx.population_pids) > 1 and rem(population.generation, interval) == 0 do
          neighbour_pids = find_neighbour_pids(ctx.population_pids, topology_fun)
          number_of_targets = Enum.random(targets_range)

          if number_of_targets > 0 and length(neighbour_pids) >= number_of_targets do
            target_pids = Enum.take_random(neighbour_pids, number_of_targets)

            %{genomes: emigrants} = pipe_through_operation(population, selection_op, ctx)

            for target_pid <- target_pids do
              send(target_pid, {:migrants, emigrants})
            end
          end
        end

        population
      end
    }
  end

  defp find_neighbour_pids(pids, topology_fun) do
    self_idx = Enum.find_index(pids, &(&1 == self()))

    pids
    |> length()
    |> topology_fun.(self_idx)
    |> Enum.map(fn neighbour_idx -> Enum.at(pids, neighbour_idx) end)
  end

  defp pipe_through_operation(population, operation, ctx) do
    pipeline = Pipeline.new([operation])
    Pipeline.apply(population, pipeline, ctx)
  end

  @doc """
  Builds an immigration operation.

  Immigration involves receiving a number of migrated
  individuals and incorporating them into the population.

  `size_to_selection_op` must be a function that given
  the shrunk population size returns a selection operation
  for that size. This effectively allows to get rid
  of some individuals and replace them with the immigrated ones.

  ## Options

    * `:interval` - the interval (number of generations)
      determining how often immigration takes place. Defaults to 1.

    * `:blocking` - whether to wait for immigration message
      if not already in the process mailbox. Setting this
      to `false` improves efficiency, but makes the algorithm
      less deterministic. Defaults to `true`.

    * `:timeout` - the number of milliseconds to await immigrants for.
      Reaching the timeout results in `RuntimeError` as it most likely
      indicates that the algorithm run into deadlock
      (populations waiting for each other). Defaults to `20_000`.
  """
  @doc type: :multi
  @spec immigrate((non_neg_integer() -> Op.t()), keyword()) :: Op.t()
  def immigrate(size_to_selection_op, opts \\ []) do
    interval = Keyword.get(opts, :interval, 1)
    blocking = Keyword.get(opts, :blocking, true)
    timeout = Keyword.get(opts, :timeout, 20_000)

    %Op{
      name: "Multi-population: immigration",
      requires_fitness: false,
      invalidates_fitness: true,
      in_representations: :any,
      impl: fn population, ctx ->
        with true <-
               length(ctx.population_pids) > 1 and rem(population.generation, interval) == 0,
             {:ok, immigrants} <- await_migrants(blocking, timeout) do
          immigrants_population = Population.new(immigrants, population.representation)

          selection_size =
            (Population.size(population) - Population.size(immigrants_population)) |> max(0)

          selection_op = size_to_selection_op.(selection_size)

          # Shrink the population to make space for immigrants
          shrunk_population = pipe_through_operation(population, selection_op, ctx)

          Population.concatenate([shrunk_population, immigrants_population])
        else
          _ -> population
        end
      end
    }
  end

  defp await_migrants(true = _blocking, timeout) do
    receive do
      {:migrants, genomes} -> {:ok, genomes}
    after
      timeout -> raise RuntimeError, "immigration timed out after #{timeout}ms"
    end
  end

  defp await_migrants(false = _blocking, _timeout) do
    receive do
      {:migrants, genomes} -> {:ok, genomes}
    after
      0 -> :error
    end
  end
end
