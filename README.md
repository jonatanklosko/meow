# Meow 🐈

[![Docs](https://img.shields.io/badge/docs-gray.svg)](https://static.jonatanklosko.com/docs/meow)

> **Disclaimer:** this is currently a work in progress.

Multipopulation evolutionary optimisation workbench

## Usage

You can define the algorithm in a single Elixir script file like this:

```elixir
# Install Meow and Nx for numerical computing

Mix.install([
  {:meow, "~> 0.1.0-dev", github: "jonatanklosko/meow"},
  {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "nx", override: true},
  {:exla, "~> 0.1.0-dev", github: "elixir-nx/nx", sparse: "exla"}
])

# Define the evaluation function, in this case using Nx to work with MeowNx

defmodule Problem do
  import Nx.Defn

  def size, do: 100

  @two_pi 2 * :math.pi()

  @defn_compiler EXLA
  defn evaluate_rastrigin(genomes) do
    sums =
      (10 + Nx.power(genomes, 2) - 10 * Nx.cos(genomes * @two_pi))
      |> Nx.sum(axes: [1])

    -sums
  end
end

# Define the evolutionary model (algorithm)

alias Meow.{Model, Pipeline}

model =
  Model.new(
    # Specify the evaluation function that we are trying to maximise
    &Problem.evaluate_rastrigin/1
  )
  |> Model.add_pipeline(
    # Define how the population is initialized and what representation to use
    MeowNx.Ops.init_real_random_uniform(100, Problem.size(), -5.12, 5.12),
    # A single pipeline corresponds to a single population
    Pipeline.new([
      # Define a number of evolutionary steps that the population goes through
      MeowNx.Ops.selection_tournament(1.0),
      MeowNx.Ops.crossover_uniform(0.5),
      MeowNx.Ops.mutation_replace_uniform(0.001, -5.12, 5.12),
      MeowNx.Ops.log_best_individual(),
      Meow.Ops.max_generations(5_000)
    ])
  )

# Execute the above model

Meow.Runner.run(model)
```

Then you can simply run the script

```shell
$ elixir example.exs

15:38:47.686 [info]  CPU Frequency: 2400000000 Hz

15:38:47.695 [info]  XLA service 0x7f70b806d830 initialized for platform Host (this does not guarantee that XLA will be used). Devices:

15:38:47.695 [info]    StreamExecutor device (0): Host, Default Version

====== Summary ======

Total time: 7.405537s
Population time (average): 7.33609s

====== Best individual ======

Fitness: -9.952529907226562
Generation: 4995
Genome: #Nx.Tensor<
  f32[100]
  [0.0014245605561882257, -0.009813232347369194, 0.02724365144968033, -0.012055663391947746, 0.029698485508561134, -0.012008056044578552, 0.022121582180261612, -0.0021472168155014515, 0.00844726525247097, -0.014771727845072746, 0.015270995907485485, 0.06452148407697678, -0.0037756345700472593, 0.002436523325741291, -8.544921875e-4, -1.8066406482830644e-4, 0.0044104005210101604, -0.028278807178139687, -0.0017431640299037099, 0.012702636420726776, -0.003321533091366291, -0.04356445372104645, -0.04323364049196243, -0.003228759625926614, 7.226562593132257e-4, -0.03388427570462227, -0.016234129667282104, 0.010357665829360485, 0.03187011554837227, -0.031779784709215164, 0.038276366889476776, -0.03178466856479645, 0.0019409179221838713, 0.0017761229537427425, 0.02133789099752903, -0.005125732161104679, -0.022709960117936134, -0.02371826209127903, -0.003442382672801614, -0.002304687397554517, 0.01475830003619194, 0.003957519307732582, 0.026345213875174522, -0.006149902008473873, 0.015958251431584358, -0.0033007811289280653, 0.9984997510910034, 0.006212158128619194, -0.0255590807646513, -0.008730468340218067, ...]
>
```

You can find more examples in the [examples](https://github.com/jonatanklosko/meow/tree/main/examples) directory.

### Interactive exploration

To iterate on different versions of your algorithm in a more interactive fashion
we recommend using [Livebook](https://github.com/elixir-nx/livebook). For a quick
introduction you can import the [Rastrigin notebook](https://github.com/jonatanklosko/meow/blob/main/notebooks/rastrigin_intro.livemd).
