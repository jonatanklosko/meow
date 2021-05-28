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

    average_time = (Enum.sum(times) / length(times)) |> Float.round()

    IO.puts("""
    Total time: #{time / 1_000_000}s
    Population time (average): #{average_time / 1_000_000}s\
    """)

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
end
