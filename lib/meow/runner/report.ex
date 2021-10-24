defmodule Meow.Runner.Report do
  @moduledoc """
  Final results and information produced during a model run.
  """

  defstruct [:total_time_us, :population_reports]

  @type t :: %__MODULE__{
          total_time_us: non_neg_integer(),
          population_reports: list(population_report())
        }

  @type population_report :: %{
          node: node(),
          time_us: non_neg_integer(),
          population: Meow.Population.t()
        }

  @doc """
  Returns a string with summarized information from the
  given report.

  If `:best_individual` is available in population log it
  gets included in the summary.
  """
  @spec format_summary(t()) :: String.t()
  def format_summary(report) do
    [
      format_times(report),
      format_best_individual(report)
    ]
    |> Enum.filter(& &1)
    |> Enum.join("\n\n")
  end

  defp format_times(report) do
    mean_time =
      report.population_reports
      |> Enum.map(& &1.time_us)
      |> mean()
      |> Float.round()

    mean_generations =
      report.population_reports
      |> Enum.map(& &1.population.generation)
      |> mean()
      |> round()

    """
    ──── Summary ────

    Total time: #{format_us(report.total_time_us)}s
    Populations: #{length(report.population_reports)}
    Population time (mean): #{format_us(mean_time)}s
    Generations (mean): #{mean_generations}\
    """
  end

  defp mean(list) do
    Enum.sum(list) / length(list)
  end

  defp format_us(time) do
    (time / 1_000_000) |> Float.round(3) |> Float.to_string()
  end

  defp format_best_individual(report) do
    report.population_reports
    |> Enum.map(& &1.population)
    |> Enum.map(fn %{log: log} -> log[:best_individual] end)
    |> Enum.reject(&is_nil/1)
    |> Enum.max_by(& &1.fitness, fn -> nil end)
    |> case do
      nil ->
        nil

      %{fitness: fitness, genome: genome, generation: generation} ->
        """
        ──── Best individual ────

        Fitness: #{fitness}
        Generation: #{generation}
        Genome: #{inspect(genome)}\
        """
    end
  end
end
