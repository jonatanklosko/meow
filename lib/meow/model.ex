defmodule Meow.Model do
  @moduledoc """
  Definition of an evolutionary model.
  """

  defstruct [:initializer, :evaluate, pipelines: []]

  alias Meow.{Population, Pipeline}

  @type t :: %__MODULE__{
          initializer: initializer(),
          evaluate: evaluate(),
          pipelines: list(Pipeline.t())
        }

  @typedoc """
  A function used to generate an initial genomes term
  according to the chosen representation.
  """
  @type initializer :: (() -> Population.genomes())

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
  @spec new(initializer(), evaluate()) :: t()
  def new(initializer, evaluate) do
    %__MODULE__{initializer: initializer, evaluate: evaluate}
  end

  @doc """
  Adds an evolutionary pipeline to the model definition.

  Each pipeline defines how a single population evolves,
  so multiple pipelines imply multi-population model.

  ## Options

    * `:duplicate` - how many copies of the pipeline to add.
      Multiple copies imply a multi-population algorithm. Defaults to 1.
  """
  @spec add_pipeline(t(), Pipeline.t()) :: t()
  def add_pipeline(model, pipeline, opts \\ []) do
    copies = Keyword.get(opts, :duplicate, 1)
    new_pipelines = List.duplicate(pipeline, copies)
    %{model | pipelines: model.pipelines ++ new_pipelines}
  end
end
