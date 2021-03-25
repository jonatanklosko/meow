defmodule Schwefel do
  @behaviour Meow.EvolutionSpec

  @dimensions 20
  # TODO: should be percentage
  # TODO: this should be configured elsewere
  @parents_count 20
  @max_number_of_fitness_evals 1_000_000

  # Problem definition

  @impl true
  def generate() do
    Stream.repeatedly(&random_x/0) |> Enum.take(@dimensions)
  end

  defp random_x() do
    -500 + :rand.uniform() * 1000
  end

  @impl true
  def evaluate(genome) do
    sum =
      genome
      |> Stream.map(fn x -> x * :math.sin(:math.sqrt(abs(x))) end)
      |> Enum.sum()

    -(418.9829 * @dimensions - sum)
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
    Meow.Strategy.Selection.tournament(population.individuals, @parents_count, 2)
  end

  @impl true
  def select_survivors(_population), do: []

  @impl true
  def crossover(genome1, genome2) do
    Meow.Strategy.Crossover.intermediate(genome1, genome2)
  end
end

# Run the algorithm

population = Meow.Evolution.run(Schwefel)
IO.inspect(population)
