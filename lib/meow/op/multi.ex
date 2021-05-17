defmodule Meow.Op.Multi do
  alias Meow.{Op, Pipeline, Population, Topology}

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
  @spec immigrate((non_neg_integer() -> Op.t()), keyword()) :: Op.t()
  def immigrate(size_to_selection_op, opts \\ []) do
    interval = Keyword.get(opts, :interval, 1)
    blocking = Keyword.get(opts, :blocking, true)
    timeout = Keyword.get(opts, :timeout, 20_000)

    %Op{
      name: "Multi-population: immigration",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        with true <-
               length(ctx.population_pids) > 1 and rem(population.generation, interval) == 0,
             {:ok, immigrants} <- await_migrants(blocking, timeout) do
          immigrants_population = Population.new(immigrants, population.representation_spec)

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
