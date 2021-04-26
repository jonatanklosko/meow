defmodule Meow.Model do
  defstruct [:initializer, :evaluate, pipelines: []]

  def new(initializer, evaluate) do
    %__MODULE__{initializer: initializer, evaluate: evaluate}
  end

  def add_pipeline(model, pipeline) do
    %{model | pipelines: model.pipelines ++ [pipeline]}
  end
end
