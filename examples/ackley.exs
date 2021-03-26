defmodule Ackley do
  @behaviour Meow.EvolutionSpec

  @dimensions 20
  @a 20
  @b 0.2
  # 2 * PI
  @c 6.2831853071795864769252866
  # exp(1)
  @e 2.71828182845904523536028747135266249775724709369995

  @mutation_scale 0.04
  @parents_count 20
  @max_number_of_fitness_evals 1_000_000

  # Problem definition

  @impl true
  def generate() do
    Stream.repeatedly(&random_x/0) |> Enum.take(@dimensions)
  end

  defp random_x do
    -32.768 + :rand.uniform() * 65.536
  end

  @impl true
  def evaluate(genome) do
    {sum1, sum2} =
      genome
      |> Enum.reduce({0, 0}, fn x, {sum1, sum2} ->
        {sum1 + x * x, sum2 + :math.cos(@c * x)}
      end)

    -(-@a * :math.exp(-@b * :math.sqrt(sum1 / @dimensions)) - :math.exp(sum2 / @dimensions) +
        @a + @e)
  end

  @impl true
  def terminate?(population) do
    population.number_of_fitness_evals >= @max_number_of_fitness_evals
  end

  # Algorithm definition

  @impl true
  def mutate(genome) do
    idx = :rand.uniform(length(genome)) - 1
    existing_gene = Enum.at(genome, idx)
    replacing_gene = existing_gene + existing_gene * (random_x() - 0.5) * @mutation_scale
    List.replace_at(genome, idx, replacing_gene)
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

population = Meow.Evolution.run(Ackley)
IO.inspect(population)
