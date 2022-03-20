defmodule MeowNx.Ops do
  @moduledoc """
  Operations backed by numerical definitions.

  This module provides a compatibility layer for `Meow`,
  while individual numerical definitions can be found
  in their respective modules.
  """

  import Nx.Defn

  alias Meow.{Op, Population}
  alias MeowNx.{Crossover, Init, Metric, Mutation, Selection}

  @representations [
    MeowNx.real_representation(),
    MeowNx.binary_representation(),
    MeowNx.permutation_representation()
  ]

  @doc """
  Builds a random initializer for the real representation.

  See `MeowNx.Init.real_random_uniform/1` for more details.
  """
  @doc type: :init
  @spec init_real_random_uniform(non_neg_integer(), non_neg_integer(), float(), float()) :: Op.t()
  def init_real_random_uniform(n, length, min, max) do
    opts = [n: n, length: length, min: min, max: max]

    %Op{
      name: "[Nx] Initialization: real random uniform",
      requires_fitness: false,
      invalidates_fitness: true,
      in_representations: :any,
      out_representation: MeowNx.real_representation(),
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn _genomes ->
          Init.real_random_uniform(opts)
        end)
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
      name: "[Nx] Initialization: binary random uniform",
      requires_fitness: false,
      invalidates_fitness: true,
      in_representations: :any,
      out_representation: MeowNx.binary_representation(),
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn _genomes ->
          Init.binary_random_uniform(opts)
        end)
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
      in_representations: @representations,
      impl: fn population, _ctx ->
        Population.map_genomes_and_fitness(population, fn genomes, fitness ->
          Selection.tournament(genomes, fitness, opts)
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
      in_representations: @representations,
      impl: fn population, _ctx ->
        Population.map_genomes_and_fitness(population, fn genomes, fitness ->
          Selection.natural(genomes, fitness, opts)
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
      in_representations: @representations,
      impl: fn population, _ctx ->
        Population.map_genomes_and_fitness(population, fn genomes, fitness ->
          Selection.roulette(genomes, fitness, opts)
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
      in_representations: @representations,
      impl: fn population, _ctx ->
        Population.map_genomes_and_fitness(population, fn genomes, fitness ->
          Selection.stochastic_universal_sampling(genomes, fitness, opts)
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
      in_representations: @representations,
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          Crossover.uniform(genomes, opts)
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
      in_representations: @representations,
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          Crossover.single_point(genomes)
        end)
      end
    }
  end

  @doc """
  Builds a multi point crossover operation.

  See `MeowNx.Crossover.multi_point/1` for more details.
  """
  @doc type: :crossover
  @spec crossover_multi_point(pos_integer()) :: Op.t()
  def crossover_multi_point(points) do
    opts = [points: points]

    %Op{
      name: "[Nx] Crossover: multi point",
      requires_fitness: false,
      invalidates_fitness: true,
      in_representations: @representations,
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          Crossover.multi_point(genomes, opts)
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
      in_representations: [MeowNx.real_representation()],
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          Crossover.blend_alpha(genomes, opts)
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
      in_representations: [MeowNx.real_representation()],
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          Crossover.simulated_binary(genomes, opts)
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
      in_representations: [MeowNx.real_representation()],
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          Mutation.replace_uniform(genomes, opts)
        end)
      end
    }
  end

  @doc """
  Builds a bit flip mutation operation.

  See `MeowNx.Mutation.replace_uniform/2` for more details.
  """
  @doc type: :mutation
  @spec mutation_bit_flip(float()) :: Op.t()
  def mutation_bit_flip(probability) do
    opts = [probability: probability]

    %Op{
      name: "[Nx] Mutation: bit flip",
      requires_fitness: false,
      invalidates_fitness: true,
      in_representations: [MeowNx.binary_representation()],
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          Mutation.bit_flip(genomes, opts)
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
      in_representations: [MeowNx.real_representation()],
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          Mutation.shift_gaussian(genomes, opts)
        end)
      end
    }
  end

  @doc """
  Builds an operation keeping track of the best individual.
  """
  @doc type: :log
  @spec log_best_individual() :: Op.t()
  def log_best_individual() do
    %Op{
      name: "[Nx] Log: best individual",
      requires_fitness: true,
      invalidates_fitness: false,
      in_representations: @representations,
      impl: fn population, _ctx ->
        {best_genome, best_fitness} =
          Metric.best_individual(population.genomes, population.fitness)
          |> Nx.backend_transfer()

        best_individual = %{
          genome: best_genome,
          fitness: Nx.to_number(best_fitness),
          generation: population.generation
        }

        update_in(population.log, fn log ->
          Map.update(log, :best_individual, best_individual, fn individual ->
            Enum.max_by([individual, best_individual], & &1.fitness)
          end)
        end)
      end
    }
  end

  @doc """
  Builds an operation loging the given set of metrics.

  Expects a map with metric functions as values. Each metric should
  be a numerical function returning a scalar tensor. The values are
  stored in a `metrics` map in the population log under the corresponding
  key.

  See `MeowNx.Metric` for a number of built-in metric definitions.

  ## Examples

      MeowNx.Ops.log_metrics(
        %{
          fitness_max: &MeowNx.Metric.fitness_max/2,
          fitness_mean: &MeowNx.Metric.fitness_mean/2,
          fitness_sd: &MeowNx.Metric.fitness_sd/2
        },
        interval: 10
      )

  ## Options

    * `:interval` - the interval (number of generations) determining
      how often the metrics are computed. Defaults to 1.
  """
  @doc type: :log
  @spec log_metrics(map(), keyword()) :: Op.t()
  def log_metrics(metrics, opts \\ []) when is_map(metrics) and is_list(opts) do
    interval = Keyword.get(opts, :interval, 1)

    {keys, funs} = Enum.unzip(metrics)
    fun = compile_metrics(funs)

    %Op{
      name: "[Nx] Log: metrics",
      requires_fitness: true,
      invalidates_fitness: false,
      in_representations: @representations,
      impl: fn population, _ctx ->
        if rem(population.generation, interval) == 0 do
          result =
            fun
            |> Nx.Defn.jit([population.genomes, population.fitness])
            |> Nx.backend_transfer()

          entries =
            result
            |> Tuple.to_list()
            |> Enum.zip(keys)
            |> Enum.map(fn {value, key} ->
              if not is_struct(value, Nx.Tensor) or Nx.shape(value) != {} do
                raise ArgumentError,
                      "expected metric function to return a scalar, but #{inspect(key)} returned #{inspect(value)}"
              end

              {key, Nx.to_number(value)}
            end)

          update_in(population.log[:metrics], fn metrics ->
            Enum.reduce(entries, metrics || %{}, fn {key, value}, metrics ->
              point = {population.generation, value}
              Map.update(metrics, key, [point], &[point | &1])
            end)
          end)
        else
          population
        end
      end
    }
  end

  # Combines many numerical functions into a single function
  # that returns all values in a tuple
  defp compile_metrics(funs) do
    fn genomes, fitness ->
      funs
      |> Enum.map(fn fun -> fun.(genomes, fitness) end)
      |> List.to_tuple()
    end
  end

  @doc """
  Clips every gene value to the closed interval `[min, max]`.
  """
  @doc type: :other
  @spec clip(number(), number()) :: Op.t()
  def clip(min, max) do
    %Op{
      name: "[Nx] Other: clip",
      requires_fitness: false,
      invalidates_fitness: true,
      in_representations: [MeowNx.real_representation()],
      impl: fn population, _ctx ->
        Population.map_genomes(population, fn genomes ->
          clip(genomes, min, max)
        end)
      end
    }
  end

  defnp clip(genomes, min, max) do
    Nx.clip(genomes, min, max)
  end
end
