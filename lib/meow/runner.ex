defmodule Meow.Runner do
  @moduledoc false

  # A module responsible for running an evolutionary algorithm,
  # as defined by `Meow.Model`.

  alias Meow.{Pipeline, Population, Op}

  # See `Meow.run/2`
  def run(model, opts \\ []) do
    nodes = opts[:nodes] || [node()]
    validate_nodes!(nodes)

    number_of_nodes = length(nodes)
    number_of_populations = length(model.pipelines)

    population_groups =
      Keyword.get_lazy(opts, :population_groups, fn ->
        even_population_groups(number_of_populations, number_of_nodes)
      end)

    validate_population_groups!(population_groups, number_of_populations, number_of_nodes)

    global_opts = opts[:global_opts] || []

    {time, result_tuples} =
      :timer.tc(&run_model/4, [model, nodes, population_groups, global_opts])

    %Meow.Report{
      total_time_us: time,
      population_reports:
        for(
          {node, time, population} <- result_tuples,
          do: %{node: node, time_us: time, population: population}
        )
    }
  end

  defp validate_nodes!(nodes) do
    if nodes == [] do
      raise ArgumentError, "expected at least one node, but got an empty list"
    end

    case nodes -- [node() | Node.list()] do
      [] ->
        :ok

      not_connected ->
        raise ArgumentError,
              "expected all nodes to be connected, but the following were not: #{Enum.join(not_connected, ", ")}"
    end
  end

  defp validate_population_groups!(population_groups, number_of_populations, number_of_nodes) do
    number_of_groups = length(population_groups)

    if number_of_groups != number_of_nodes do
      raise ArgumentError,
            "expected the same number of population groups and nodes, but got different (#{number_of_groups} != #{number_of_nodes})"
    end

    indices = population_groups |> List.flatten() |> Enum.sort()
    expected_indices = Enum.to_list(0..(number_of_populations - 1))

    if indices != expected_indices do
      raise ArgumentError,
            "expected every population to be assigned to one of the population groups," <>
              "\n  unexpected: #{inspect(indices -- expected_indices)}" <>
              "\n  missing: #{inspect(expected_indices -- indices)}"
    end
  end

  defp even_population_groups(number_of_populations, number_of_nodes) do
    indices = Enum.to_list(0..(number_of_populations - 1))
    Meow.Utils.split_evenly(indices, number_of_nodes)
  end

  defp run_model(model, nodes, population_groups, global_opts) do
    runner_pid = self()

    population_node_mapping =
      for {node, indices} <- Enum.zip(nodes, population_groups),
          idx <- indices,
          into: %{},
          do: {idx, node}

    pids =
      model.pipelines
      |> Enum.with_index()
      |> Enum.map(fn {{initializer, pipeline}, idx} ->
        node = population_node_mapping[idx]

        Node.spawn_link(node, fn ->
          receive do
            {:initialize, pids} ->
              ctx = %Op.Context{
                evaluate: model.evaluate,
                population_pids: pids,
                global_opts: global_opts
              }

              population = Op.apply(%Population{}, initializer, ctx)

              {time, final_population} = :timer.tc(&run_population/3, [population, pipeline, ctx])
              send(runner_pid, {:finished, self(), node, time, final_population})
          end
        end)
      end)

    for pid <- pids, do: send(pid, {:initialize, pids})

    for pid <- pids do
      receive do
        {:finished, ^pid, node, time, population} -> {node, time, population}
      end
    end
  end

  defp run_population(population, pipeline, ctx) do
    population = Pipeline.apply(population, pipeline, ctx)

    if population.terminated do
      population
    else
      population
      |> Map.update!(:generation, &(&1 + 1))
      |> run_population(pipeline, ctx)
    end
  end
end
