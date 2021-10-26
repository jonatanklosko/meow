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

  # Plotting

  # Ensures `VegaLite` is available and raises an error otherwise.
  defp assert_vega_lite!(fn_name) do
    unless Code.ensure_loaded?(VegaLite) do
      raise RuntimeError, """
      #{fn_name} depends on the :vega_lite package.
      You can install it by adding

          {:vega_lite, "~> 0.1.1"}

      to your dependency list.
      """
    end
  end

  @compile {:no_warn_undefined, VegaLite}

  alias VegaLite, as: Vl

  @doc """
  Returns concatenated plots for all metrics.

  See `plot_metric/3` for plotting only a specific metric.
  """
  @spec plot_metrics(t()) :: VegaLite.t()
  def plot_metrics(report) do
    assert_vega_lite!("plot_metrics/1")

    metrics =
      for %{population: population} <- report.population_reports,
          {metric, _} <- population.log.metrics,
          uniq: true,
          do: metric

    plots = Enum.map(metrics, &plot_metric(report, &1))
    Vl.concat(Vl.new(), plots, :vertical)
  end

  @doc """
  Plots the given metric from population logs.

  ## Options

    * `:arrange` - controls how multiple populations are plotted,
      either `:color` (layered plot) or `:grid` (separate plots).
      Defaults to `:color`
  """
  @spec plot_metric(t(), atom(), keyword()) :: VegaLite.t()
  def plot_metric(report, metric, opts \\ []) do
    assert_vega_lite!("plot_metric/3")

    arrange = opts[:arrange] || :color

    data =
      for {%{population: population}, idx} <- Enum.with_index(report.population_reports),
          {generation, value} <- population.log.metrics[metric],
          do: %{
            population: "population #{idx}",
            generation: generation,
            value: value
          }

    vl =
      case arrange do
        :color ->
          Vl.new(width: 500, height: 500)
          |> Vl.encode_field(:color, "population", type: :nominal)

        :grid ->
          Vl.new(width: 240, height: 240)
          |> Vl.encode_field(:facet, "population", type: :nominal, columns: 3)
      end

    vl
    |> Vl.data_from_values(data)
    # Use unique parameter name in case multiple metric plots are stacked
    |> Vl.param("#{metric}_region", select: :interval, bind: :scales)
    |> Vl.mark(:line)
    |> Vl.encode_field(:x, "generation", type: :quantitative, title: "generation")
    |> Vl.encode_field(:y, "value", type: :quantitative, title: Atom.to_string(metric))
  end
end
