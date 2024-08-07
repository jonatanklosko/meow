# Meow 🐈

[![Docs](https://img.shields.io/badge/docs-gray.svg)](https://static.jonatanklosko.com/docs/meow)

> **Disclaimer:** this is currently a work in progress.

Multi-population evolutionary optimisation workbench

## Usage

You can define the algorithm in a single Elixir script file like this:

```elixir
# Install Meow and Nx for numerical computing

Mix.install([
  {:meow, "~> 0.1.0-dev", github: "jonatanklosko/meow"},
  {:nx, "~> 0.7.0"},
  {:exla, "~> 0.7.0"}
])

Nx.Defn.global_default_options(compiler: EXLA)

# Define the evaluation function, in this case using Nx to work with MeowNx

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

# Define the evolutionary algorithm

algorithm =
  Meow.objective(
    # Specify the evaluation function that we are trying to maximise
    &Problem.evaluate_rastrigin/1
  )
  |> Meow.add_pipeline(
    # Define how the population is initialized and what representation to use
    MeowNx.Ops.init_real_random_uniform(100, Problem.size(), -5.12, 5.12),
    # A single pipeline corresponds to a single population
    Meow.pipeline([
      # Define a number of evolutionary steps that the population goes through
      MeowNx.Ops.selection_tournament(1.0),
      MeowNx.Ops.crossover_uniform(0.5),
      MeowNx.Ops.mutation_replace_uniform(0.001, -5.12, 5.12),
      MeowNx.Ops.log_best_individual(),
      Meow.Ops.max_generations(5_000)
    ])
  )


# Execute the above algorithm

report = Meow.run(algorithm)

report |> Meow.Report.format_summary() |> IO.puts()
```

Then you simply run the script

```shell
$ elixir example.exs

──── Summary ────

Total time: 5.993s
Populations: 1
Population time (mean): 5.746s
Generations (mean): 5000

──── Best individual ────

Fitness: -9.421020843939452
Generation: 4982
Genome: #Nx.Tensor<
  f64[100]
  EXLA.Backend<host:0, 0.3115944784.4181327880.13497>
  [0.009958496317267418, 0.04785522446036339, 0.017037352547049522, -0.017465820536017418, -0.017824707552790642, 0.008717365553470262, -0.032379150390625, 8.666992071084678e-4, 0.001085205003619194, 0.023798827081918716, -0.0013952635927125812, 0.0050024413503706455, 0.013221435248851776, -0.011859131045639515, -0.07148071378469467, -0.0018774414202198386, -0.005152587778866291, -0.005764159839600325, -0.013275146484375, -0.012554931454360485, 7.470702985301614e-4, 0.024797363206744194, 0.018918546728446277, 0.018818359822034836, 0.03758788853883743, 0.0024987792130559683, -0.01250610314309597, 3.4667967702262104e-4, 0.025520019233226776, -0.014041747897863388, 0.0024865721352398396, -0.00942260678857565, -0.0036364744883030653, 0.001259765587747097, 0.020170897245407104, 0.03543701022863388, 0.01214599609375, -0.008547362871468067, 0.008267821744084358, -0.008248290978372097, 0.009224853478372097, -0.009011230431497097, -0.01357421837747097, -0.0022021483164280653, 0.002288818359375, 0.009760742075741291, -0.01131591759622097, 0.04674072191119194, -0.0051379394717514515, -0.035057373344898224, ...]
>
```

Check out more examples in the [examples](https://github.com/jonatanklosko/meow/blob/main/examples) directory.

### Interactive exploration

To iterate on different versions of your algorithm in a more interactive fashion
we recommend using [Livebook](https://livebook.dev). For a quick introduction you
can import the [Rastrigin notebook](https://github.com/jonatanklosko/meow/blob/main/notebooks/rastrigin_intro.livemd).

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fjonatanklosko%2Fmeow%2Fblob%2Fmain%2Fnotebooks%2Frastrigin_intro.livemd)

## License

Copyright (C) 2021 Jonatan Kłosko and Mateusz Benecki

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
