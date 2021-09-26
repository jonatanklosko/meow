defmodule Meow.Model do
  @moduledoc """
  Definition of an evolutionary model.
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

  @doc """
  Entrypoint for building a new model definition.
  """
  @spec new(evaluate()) :: t()
  def new(evaluate) do
    %__MODULE__{evaluate: evaluate}
  end

  @doc """
  Adds an evolutionary pipeline to the model definition.

  Each pipeline defines how a single population evolves,
  so multiple pipelines imply multi-population model.

  When the model is run, `initializer` is aplied to an empty
  population, then the resulting population is repeatedly
  passed through the pipeline until termination.

  ## Options

    * `:duplicate` - how many copies of the pipeline to add.
      Multiple copies imply a multi-population algorithm. Defaults to 1.
  """
  @spec add_pipeline(t(), Op.t(), Pipeline.t()) :: t()
  def add_pipeline(model, initializer, pipeline, opts \\ []) do
    validate_initializer!(initializer)
    validate_pipeline!(pipeline, initializer.out_representation)

    copies = Keyword.get(opts, :duplicate, 1)
    new_pipelines = List.duplicate({initializer, pipeline}, copies)
    %{model | pipelines: model.pipelines ++ new_pipelines}
  end

  defp validate_initializer!(op) do
    # If the operation doesn't explicitly specify the output representation
    # it's not an initializer
    if op.out_representation == :same do
      raise ArgumentError, "expected an initializer operation, got: #{inspect(op.name)}"
    end
  end

  def validate_pipeline!(pipeline, representation) do
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
