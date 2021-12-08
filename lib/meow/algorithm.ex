defmodule Meow.Algorithm do
  @moduledoc """
  Definition of an evolutionary algorithm.
  """

  defstruct [:evaluate, pipelines: []]

  alias Meow.{Population, Pipeline, Op}

  @type t :: %__MODULE__{
          evaluate: evaluate(),
          pipelines: list({initializer :: Op.t(), pipeline :: Pipeline.t()})
        }

  @typedoc """
  A function used to calculate the assessment of all
  individual genomes in a population.

  Essentially, this is the optimisation objective,
  except the calculation is supposed to work on a batch
  of genomes. Note that higher values should indicate
  a better solution (individual), hence the evolutionary
  process is going to try maximising this function.
  """
  @type evaluate :: (Population.genomes() -> Population.fitness())

  @doc false
  # See `Meow.objective/1`
  def new(evaluate) do
    %__MODULE__{evaluate: evaluate}
  end

  @doc false
  # See `Meow.add_pipeline/4`
  def add_pipeline(algorithm, initializer, pipeline, opts \\ []) do
    validate_initializer!(initializer)
    validate_pipeline!(pipeline, initializer.out_representation)

    copies = Keyword.get(opts, :duplicate, 1)
    new_pipelines = List.duplicate({initializer, pipeline}, copies)
    %{algorithm | pipelines: algorithm.pipelines ++ new_pipelines}
  end

  defp validate_initializer!(op) do
    # If the operation doesn't explicitly specify the output representation
    # it's not an initializer
    if op.out_representation == :same do
      raise ArgumentError, "expected an initializer operation, got: #{inspect(op.name)}"
    end
  end

  defp validate_pipeline!(pipeline, representation) do
    ops =
      case pipeline.ops do
        [] -> []
        [first | ops] -> [first | ops] ++ [first]
      end

    Enum.reduce(ops, representation, fn op, representation ->
      if op.in_representations != :any and representation not in op.in_representations do
        raise ArgumentError,
              "representation mismatch, #{inspect(op.name)} does not accept #{inspect(representation)}"
      end

      case op.out_representation do
        :same -> representation
        other -> other
      end
    end)
  end
end
