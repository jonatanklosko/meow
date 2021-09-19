defmodule MeowNx.Ops do
  @moduledoc """
  Operations backed by numerical definitions.

  This module provides a compatibility layer for `Meow`,
  while individual numerical definitions can be found
  in their respective modules.
  """

  alias Meow.Op
  alias MeowNx.{Crossover, Init, Metric, Mutation, Selection}
  alias MeowNx.Utils

  @doc """
  Builds a random initializer for the real representation.

  See `MeowNx.Init.real_random_uniform/1` for more details.
  """
  @doc type: :init
  @spec init_real_random_uniform(non_neg_integer(), non_neg_integer(), float(), float()) :: Op.t()
  def init_real_random_uniform(n, length, min, max) do
    opts = [n: n, length: length, min: min, max: max]

    %Op{
      name: "[Nx] Initialization: random uniform",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        genomes = Nx.Defn.jit(fn -> Init.real_random_uniform(opts) end, [], Utils.jit_opts(ctx))
        %{population | genomes: genomes, representation_spec: MeowNx.RepresentationSpec}
      end
    }
  end

  @doc """
  Builds a random initializer for the binary representation.

  See `MeowNx.Init.binary_random_uniform/1` for more details.
  """
  @doc type: :init
  @spec init_binary_random_uniform(non_neg_integer(), non_neg_integer()) :: Op.t()
  def init_binary_random_uniform(n, length) do
    opts = [n: n, length: length]

    %Op{
      name: "[Nx] Initialization: random uniform",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        genomes = Nx.Defn.jit(fn -> Init.binary_random_uniform(opts) end, [], Utils.jit_opts(ctx))
        %{population | genomes: genomes, representation_spec: MeowNx.RepresentationSpec}
      end
    }
  end

  @doc """
  Builds a tournament selection operation.

  See `MeowNx.Selection.tournament/3` for more details.
  """
  @doc type: :selection
  @spec selection_tournament(non_neg_integer() | float()) :: Op.t()
  def selection_tournament(n) do
    opts = [n: n]

    %Op{
      name: "[Nx] Selection: tournament",
      requires_fitness: true,
      invalidates_fitness: false,
      impl: fn population, ctx ->
        Op.map_genomes_and_fitness(population, fn genomes, fitness ->
          Nx.Defn.jit(
            &Selection.tournament(&1, &2, opts),
            [genomes, fitness],
            Utils.jit_opts(ctx)
          )
        end)
      end
    }
  end

  @doc """
  Builds a natural selection operation.

  See `MeowNx.Selection.natural/3` for more details.
  """
  @doc type: :selection
  @spec selection_natural(non_neg_integer() | float()) :: Op.t()
  def selection_natural(n) do
    opts = [n: n]

    %Op{
      name: "[Nx] Selection: natural",
      requires_fitness: true,
      invalidates_fitness: false,
      impl: fn population, ctx ->
        Op.map_genomes_and_fitness(population, fn genomes, fitness ->
          Nx.Defn.jit(&Selection.natural(&1, &2, opts), [genomes, fitness], Utils.jit_opts(ctx))
        end)
      end
    }
  end

  @doc """
  Builds a roulette selection operation.

  See `MeowNx.Selection.roulette/3` for more details.
  """
  @doc type: :selection
  @spec selection_roulette(non_neg_integer() | float()) :: Op.t()
  def selection_roulette(n) do
    opts = [n: n]

    %Op{
      name: "[Nx] Selection: roulette",
      requires_fitness: true,
      invalidates_fitness: false,
      impl: fn population, ctx ->
        Op.map_genomes_and_fitness(population, fn genomes, fitness ->
          Nx.Defn.jit(&Selection.roulette(&1, &2, opts), [genomes, fitness], Utils.jit_opts(ctx))
        end)
      end
    }
  end

  @doc """
  Builds a stochastic universal sampling operation.

  See `MeowNx.Selection.stochastic_universal_sampling/3` for more details.
  """
  @doc type: :selection
  @spec selection_stochastic_universal_sampling(non_neg_integer() | float()) :: Op.t()
  def selection_stochastic_universal_sampling(n) do
    opts = [n: n]

    %Op{
      name: "[Nx] Selection: stoachastic universal sampling",
      requires_fitness: true,
      invalidates_fitness: false,
      impl: fn population, ctx ->
        Op.map_genomes_and_fitness(population, fn genomes, fitness ->
          Nx.Defn.jit(
            &Selection.stochastic_universal_sampling(&1, &2, opts),
            [genomes, fitness],
            Utils.jit_opts(ctx)
          )
        end)
      end
    }
  end

  @doc """
  Builds a uniform crossover operation.

  See `MeowNx.Crossover.uniform/2` for more details.
  """
  @doc type: :crossover
  @spec crossover_uniform(float()) :: Op.t()
  def crossover_uniform(probability \\ 0.5) do
    opts = [probability: probability]

    %Op{
      name: "[Nx] Crossover: uniform",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Crossover.uniform(&1, opts), [genomes], Utils.jit_opts(ctx))
        end)
      end
    }
  end

  @doc """
  Builds a single point crossover operation.

  See `MeowNx.Crossover.single_point/1` for more details.
  """
  @doc type: :crossover
  @spec crossover_single_point() :: Op.t()
  def crossover_single_point() do
    %Op{
      name: "[Nx] Crossover: single point",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Crossover.single_point(&1), [genomes], Utils.jit_opts(ctx))
        end)
      end
    }
  end

  @doc """
  Builds a blend-alpha crossover operation.

  See `MeowNx.Crossover.blend_alpha/2` for more details.
  """
  @doc type: :crossover
  @spec crossover_blend_alpha(float()) :: Op.t()
  def crossover_blend_alpha(alpha \\ 0.5) do
    opts = [alpha: alpha]

    %Op{
      name: "[Nx] Crossover: blend-alpha",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Crossover.blend_alpha(&1, opts), [genomes], Utils.jit_opts(ctx))
        end)
      end
    }
  end

  @doc """
  Builds a simulated binary crossover operation.

  See `MeowNx.Crossover.simulated_binary/2` for more details.
  """
  @doc type: :crossover
  @spec crossover_simulated_binary(float()) :: Op.t()
  def crossover_simulated_binary(eta) do
    opts = [eta: eta]

    %Op{
      name: "[Nx] Crossove: simulated binary",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Crossover.simulated_binary(&1, opts), [genomes], Utils.jit_opts(ctx))
        end)
      end
    }
  end

  @doc """
  Builds a uniform replacement mutation operation.

  See `MeowNx.Mutation.replace_uniform/2` for more details.
  """
  @doc type: :mutation
  @spec mutation_replace_uniform(float(), float(), float()) :: Op.t()
  def mutation_replace_uniform(probability, min, max) do
    opts = [probability: probability, min: min, max: max]

    %Op{
      name: "[Nx] Mutation: replace uniform",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Mutation.replace_uniform(&1, opts), [genomes], Utils.jit_opts(ctx))
        end)
      end
    }
  end

  @doc """
  Builds a bit-flip mutation operation.

  See `MeowNx.Mutation.replace_uniform/2` for more details.
  """
  @doc type: :mutation
  @spec mutation_bit_flip(float()) :: Op.t()
  def mutation_bit_flip(probability) do
    opts = [probability: probability]

    %Op{
      name: "[Nx] Mutation: replace uniform",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Mutation.bit_flip(&1, opts), [genomes], Utils.jit_opts(ctx))
        end)
      end
    }
  end

  @doc """
  Builds a Gaussian shift mutation operation.

  See `MeowNx.Mutation.shift_gaussian/2` for more details.
  """
  @doc type: :mutation
  @spec mutation_shift_gaussian(float(), keyword()) :: Op.t()
  def mutation_shift_gaussian(probability, opts \\ []) do
    opts = opts |> Keyword.take([:sigma]) |> Keyword.put(:probability, probability)

    %Op{
      name: "[Nx] Mutation: shift Gaussian",
      requires_fitness: false,
      invalidates_fitness: true,
      impl: fn population, ctx ->
        Op.map_genomes(population, fn genomes ->
          Nx.Defn.jit(&Mutation.shift_gaussian(&1, opts), [genomes], Utils.jit_opts(ctx))
        end)
      end
    }
  end

  @doc """
  Builds a metric operation loging the best individual.

  See `MeowNx.Metric.best_individual/2` for more details.
  """
  @doc type: :metric
  @spec metric_best_individual() :: Op.t()
  def metric_best_individual() do
    %Op{
      name: "Metric: best individual",
      requires_fitness: true,
      invalidates_fitness: false,
      impl: fn population, ctx ->
        {best_genome, best_fitness} =
          Nx.Defn.jit(
            &Metric.best_individual/2,
            [population.genomes, population.fitness],
            Utils.jit_opts(ctx)
          )

        best_individual = %{
          genome: best_genome,
          fitness: Nx.to_scalar(best_fitness),
          generation: population.generation
        }

        update_in(population.metrics, fn metrics ->
          Map.update(metrics, :best_individual, best_individual, fn individual ->
            Enum.max_by([individual, best_individual], & &1.fitness)
          end)
        end)
      end
    }
  end
end
