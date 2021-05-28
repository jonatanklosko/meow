defmodule Meow.Runner do
  @moduledoc """
  A module responsible for running an evolutionary
  algorithm, as defined by `Meow.Model`.
  """

  alias Meow.{Population, Pipeline, Model}

  @doc """
  Iteratively transforms populations according to
  the given model until the populations are terminated.
  """
  @spec run(Model.t()) :: list(Population.t())
  def run(model) do
    {time, {times, populations}} = :timer.tc(&run_model/1, [model])

    IO.write([
      format_times(time, times),
      format_best_individual(populations)
    ])

    populations
  end

  defp run_model(model) do
    runner_pid = self()

    pids =
      Enum.map(model.pipelines, fn pipeline ->
        spawn_link(fn ->
          {genomes, representation_spec} = model.initializer.()
          population = Population.new(genomes, representation_spec)

          receive do
            {:initialize, pids} ->
              ctx = %{evaluate: model.evaluate, population_pids: pids}
              {time, final_population} = :timer.tc(&run_population/3, [population, pipeline, ctx])
              send(runner_pid, {:finished, self(), time, final_population})
          end
        end)
      end)

    for pid <- pids, do: send(pid, {:initialize, pids})

    pids
    |> Enum.map(fn pid ->
      receive do
        {:finished, ^pid, time, population} -> {time, population}
      end
    end)
    |> Enum.unzip()
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

  defp format_times(total_time, times) do
    average_time = (Enum.sum(times) / length(times)) |> Float.round()

    """
    \n====== Summary ======

    Total time: #{total_time / 1_000_000}s
    Population time (average): #{average_time / 1_000_000}s
    """
  end

  defp format_best_individual(populations) do
    populations
    |> Enum.map(fn %{metrics: metrics} -> metrics[:best_individual] end)
    |> Enum.reject(&is_nil/1)
    |> Enum.max_by(& &1.fitness, fn -> nil end)
    |> case do
      nil ->
        ""

      %{fitness: fitness, genome: genome, generation: generation} ->
        """
        \n====== Best individual ======

        Fitness: #{fitness}
        Generation: #{generation}
        Genome: #{inspect(genome)}
        """
    end
  end
end
