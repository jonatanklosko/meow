defmodule Examples.Rastrigin do
  @behaviour Meow.EvolutionSpec

  @dimensions 100
  # TODO: should be percentage
  # TODO: this should also be configured elsewere
  @parents_count 20
  @max_number_of_fitness_evals 1_000_000

  # Problem definition

  @impl true
  def generate() do
    Stream.repeatedly(&random_x/0) |> Enum.take(@dimensions)
  end

  defp random_x() do
    -5.12 + :rand.uniform() * 10.24
  end

  @impl true
  def evaluate(genome) do
    genome
    |> Stream.map(fn x -> 10 + x * x - 10 * :math.cos(2 * :math.pi() * x) end)
    |> Enum.sum()
    |> Kernel.-()
  end

  @impl true
  def terminate?(population) do
    population.number_of_fitness_evals >= @max_number_of_fitness_evals
  end

  # Algorithm definition

  @impl true
  def mutate(genome) do
    idx = :rand.uniform(length(genome)) - 1
    random_gene = random_x()
    List.replace_at(genome, idx, random_gene)
  end

  @impl true
  def select_parents(population) do
    # Note: tournament selection with 2 participants
    Stream.repeatedly(fn ->
      population.individuals
      |> Enum.take_random(2)
      |> Enum.max_by(& &1.fitness)
    end)
    |> Enum.take(@parents_count)
  end

  @impl true
  def select_survivors(_population) do
    []
  end

  @impl true
  def crossover(genome1, genome2) do
    # Note: uniform crossover with 0.5 probability
    genome1
    |> Enum.zip(genome2)
    |> Enum.map(fn {gene1, gene2} ->
      if :rand.uniform() < 0.5 do
        {gene1, gene2}
      else
        {gene2, gene1}
      end
    end)
    |> Enum.unzip()
  end
end
