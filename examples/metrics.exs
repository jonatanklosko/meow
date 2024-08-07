Mix.install([
  {:meow, "~> 0.1.0-dev", github: "jonatanklosko/meow"},
  {:nx, "~> 0.7.0"},
  {:exla, "~> 0.7.0"},
  {:vega_lite, "~> 0.1.1"},
  {:jason, "~> 1.4"}
])

Nx.Defn.global_default_options(compiler: EXLA)

defmodule Problem do
  import Nx.Defn

  def size, do: 100

  @two_pi 2 * :math.pi()

  defn evaluate_rastrigin(genomes) do
    sums =
      (10 + Nx.pow(genomes, 2) - 10 * Nx.cos(genomes * @two_pi))
      |> Nx.sum(axes: [1])

    -sums
  end
end

algorithm =
  Meow.objective(&Problem.evaluate_rastrigin/1)
  |> Meow.add_pipeline(
    MeowNx.Ops.init_real_random_uniform(100, Problem.size(), -5.12, 5.12),
    Meow.pipeline([
      MeowNx.Ops.selection_tournament(1.0),
      MeowNx.Ops.crossover_uniform(0.5),
      MeowNx.Ops.mutation_shift_gaussian(0.001),
      MeowNx.Ops.log_best_individual(),
      MeowNx.Ops.log_metrics(
        %{
          fitness_max: &MeowNx.Metric.fitness_max/2,
          fitness_mean: &MeowNx.Metric.fitness_mean/2,
          fitness_sd: &MeowNx.Metric.fitness_sd/2
        },
        interval: 100
      ),
      Meow.Ops.max_generations(5_000)
    ])
  )

report = Meow.run(algorithm)
%{population_reports: [%{population: population}]} = report

IO.puts("\nLogged metrics:")
IO.inspect(population.log.metrics)

report_path = Path.expand("tmp/report.html")
report_path |> Path.dirname() |> File.mkdir_p!()
:ok = Meow.Report.export_html(report, report_path)
IO.puts("Report saved to #{report_path}")
