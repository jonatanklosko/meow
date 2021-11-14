defmodule Meow do
  @moduledoc ~S"""
  Meow is a framework for composing and running evolutionary
  algorithms, with support for multi-population variants and
  distributed computing.

  ## Concepts

  In Meow an evolutionary algorithm is defined as a pipeline
  of operations that the population goes through, until the
  termination criteria is met. Each operation is a building
  block that transforms the population in some way.

  A single pipeline describes the evolution of one population,
  and by defining multiple pipelines we effectively get a
  multi-population algorithm. Also, if there are multiple
  populations, we generally want them to communicate, which
  can be achieved by including a migration step in the pipelines.

  ## Example

  We will start with an easy and predictable example. Let's
  consider a simple multivariable function that takes a sum of
  all the arguments.

  $$
  f(x_0, ..., x_n) = x_0 + ... + x_n
  $$

  Or in vector notation:

  $$
  f(x) = \sum_{i} x_i
  $$

  Additionally, let's assume each argument can be either $0$ or $1$,
  so a possible argument would look like this:

  $$
  x_0 = \begin{bmatrix}
  0 & 1 & 1 & 0 & 1 & 0 \\\\
  \end{bmatrix} \\\\
  $$

  Our objective is to **maximise** this function.

  In evolutionary terms $x_0$ is an individual genome with each gene
  being either $0$ or $1$, whereas $f$ is the **fitness** function that
  tells us how good the given individual is. Consequently our objective
  is to generate an individual with the highest fitness possible.

  There's not much we can do with a single individual, so we get more
  of these and form a **population**:

  $$
  X = \begin{bmatrix}
  0 & 1 & 1 & 0 & 1 & 0 \\\\
  1 & 1 & 0 & 0 & 0 & 1 \\\\
  0 & 0 & 1 & 1 & 1 & 0 \\\\
  1 & 0 & 1 & 0 & 1 & 1
  \end{bmatrix}
  $$

  The basic idea behind an evolutionary algorithm is to let this population
  evolve over time, until we generate a very fit individual. To do this,
  we use various operations, such as:

    * **selection** - picking individuals based on their properties

    * **crossover** - taking a number of individuals (parents) and combining
      them to produce new individuals (children)

    * **mutation** - altering some genes in a random fashion

  These are just a few basic groups, but in practice operations may do any
  transformations, with the eventual goal of improving the population.

  ### Coding it up

  Let's see how we can use Meow to put all of these terms into code.
  The first thing we need is to define the fitness function.

      defmodule Problem do
        import Nx.Defn

        def size, do: 100

        @defn_compiler EXLA
        defn f(genomes) do
          Nx.sum(genomes, axes: [1])
        end
      end

  Since we are dealing with heavily numerical problems we use Elixir Nx
  to work with numbers. Meow core doesn't assume that, but most of the
  built-in operations use Nx underneath (see `MeowNx`).

  Also, note that the function above calculates fitness for the whole population,
  so the returned value is a vector of fitness values.

  At this point we have already defined what problem we are trying to solve, the
  only missing piece is an algorithm to solve it.

      model =
        Meow.objective(&Problem.f/1)
        |> Meow.add_pipeline(
          MeowNx.Ops.init_binary_random_uniform(100, Problem.size()),
          Meow.pipeline([
            MeowNx.Ops.selection_tournament(1.0),
            MeowNx.Ops.crossover_uniform(0.5),
            MeowNx.Ops.mutation_bit_flip(0.001),
            MeowNx.Ops.log_best_individual(),
            Meow.Ops.max_generations(100)
          ])
        )

  Let's break down what we just did. We start modeling our algorithm by
  specifying the objective function `f`. Then we specify how the population
  should be initialised, in this case we generate 100 individuals, each with
  `Problem.size()` genes. Finally, we list the operations that should be
  applied to the population on every iteration.

  Now we just need to run our algorithm:

      report = Meow.run(model)
      report |> Meow.Report.format_summary() |> IO.puts()

  Hopefully this gives us a good solution to our problem, in this case an
  individual with all genes set to 1.

  By its nature, those algorithms are random in nature and fall under
  the category of heuristics. Nonetheless for a number of problems heuristics
  are the best we have and Meow attempts to make experimentation easy and
  efficient.

  ## Learn more

  The above example presents a simple single-population model, but there's
  much more you can do with Meow. Check out the Guides section for interactive
  notebooks that you can easily try out yourself. Additionally, there's a number
  of examples in the GitHub repository, so feel free explore those too.
  """

  @doc """
  Entry point for building a new evolutionary model.

  The given function becomes the optimisation objective
  that the algorithm will try to maximise.
  """
  @spec objective(Meow.Model.evaluate()) :: Meow.Model.t()
  defdelegate objective(evaluate), to: Meow.Model, as: :new

  @doc """
  Builds a new pipeline from a list of operations.
  """
  @spec pipeline(list(Meow.Op.t())) :: Meow.Pipeline.t()
  defdelegate pipeline(ops), to: Meow.Pipeline, as: :new

  @doc """
  Adds an evolutionary pipeline to the model definition.

  Each pipeline defines how a single population evolves,
  so multiple pipelines imply multi-population model.

  When the model is run, `initializer` is applied to an empty
  population, then the resulting population is repeatedly
  passed through the pipeline until termination.

  ## Options

    * `:duplicate` - how many copies of the pipeline to add.
      Multiple copies imply a multi-population algorithm. Defaults to 1.
  """
  @spec add_pipeline(Meow.Model.t(), Meow.Op.t(), Meow.Pipeline.t(), keyword()) :: Meow.Model.t()
  defdelegate add_pipeline(model, initializer, pipeline, opts \\ []), to: Meow.Model

  @doc """
  Iteratively transforms populations according to the given
  model until all populations are terminated.

  ## Distribution

  In case of a multi-population algorithm the populations
  evolve in parallel, by default within the current runtime.

  If multiple runtime nodes are available, the algorithm may
  be run in a distributed setup by specifying the `:nodes`
  option. In that case the populations are distributed among
  said nodes, which can be further controlled with the
  `:population_groups` option.

  ## Options

    * `:nodes` - a list of nodes available for running the
      algorithm. Note that all of the nodes must be already
      connected and all relevant modules must be available
      for every node. Defaults to `[node()]`.

    * `:population_groups` - a list of groups, where each
      group is a list of population indices. Populations
      from the same group will be run on the same node.
      The number of groups should match the number of nodes
      configured via `:nodes` and every population must be
      in exactly one of the groups. By default populations
      are split into even groups.
  """
  @spec run(Meow.Model.t(), keyword()) :: Meow.Report.t()
  defdelegate run(model, opts \\ []), to: Meow.Runner
end
