defmodule Meow.Strategy.Selection do
  @moduledoc """
  Provides a number of well known selection strategies.
  """

  alias Meow.Individual

  @doc """
  Implements tournament selection.

  Simulates `n` tournaments of `tournament_size` random individuals
  and returns the list of winners (based on fitness).
  """
  @spec tournament(list(Individual.t()), non_neg_integer(), pos_integer()) :: list(Individual.t())
  def tournament(individuals, n, tournament_size \\ 2) do
    Stream.repeatedly(fn ->
      individuals
      |> Enum.take_random(tournament_size)
      |> Enum.max_by(& &1.fitness)
    end)
    |> Enum.take(n)
  end
end
