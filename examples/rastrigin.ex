Mix.install([
  {:exla, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "exla"},
  {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "nx", override: true},
  {:benchee, "~> 1.0"},
  {:meow, path: __DIR__ |> Path.join("..") |> Path.expand()}
])

defmodule Rastrigin do
  import Nx.Defn
  alias Meow.{Model, Pipeline}
  alias Meow.Op.Termination
  alias MeowNx.Init
  alias MeowNx.Op.{Selection, Crossover, Mutation}

  def model() do
    Model.new(
      Init.real_random_uniform(20, 100, -5.12, 5.12),
      &evaluate/1
    )
    |> Model.add_pipeline(
      Pipeline.new([
        Selection.tournament(20),
        Crossover.uniform(0.5),
        Mutation.replace_random_uniform(0.001, -5.12, 5.12),
        Termination.max_generations(50000)
      ])
    )
  end

  @two_pi 2 * :math.pi()

  @defn_compiler EXLA
  defn evaluate(genomes) do
    sums =
      (10 + Nx.power(genomes, 2) - 10 * Nx.cos(genomes * @two_pi))
      |> Nx.sum(axes: [1])

    -sums
  end
end

:timer.tc(fn -> Meow.Runner.run(Rastrigin.model()) end) |> IO.inspect()
