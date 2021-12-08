defmodule Meow.AlgorithmTest do
  use ExUnit.Case, async: true

  alias Meow.{Algorithm, Op, Pipeline}

  describe "add_pipeline/4" do
    test "raises an error when initializer operation doesn't have explicit output representation" do
      algorithm = Algorithm.new(fn _, _ -> :ok end)

      non_initializer = %Op{
        name: "Non-initializer",
        requires_fitness: false,
        invalidates_fitness: true,
        in_representations: :any,
        out_representation: :same,
        impl: fn population, _ctx -> population end
      }

      assert_raise ArgumentError,
                   ~s/expected an initializer operation, got: "Non-initializer"/,
                   fn ->
                     Algorithm.add_pipeline(algorithm, non_initializer, Pipeline.new([]))
                   end
    end

    test "raises an error on representation mismatch within the pipeline" do
      algorithm = Algorithm.new(fn _, _ -> :ok end)

      real_initializer = %Op{
        name: "Real initializer",
        requires_fitness: false,
        invalidates_fitness: true,
        in_representations: :any,
        out_representation: {Meow.TestRepresentationSpec, :real},
        impl: fn population, _ctx -> population end
      }

      real_selection = %Op{
        name: "Real selection",
        requires_fitness: true,
        invalidates_fitness: false,
        in_representations: [{Meow.TestRepresentationSpec, :real}],
        out_representation: :same,
        impl: fn population, _ctx -> population end
      }

      binary_crossover = %Op{
        name: "Binary crossover",
        requires_fitness: false,
        invalidates_fitness: true,
        in_representations: [{Meow.TestRepresentationSpec, :binary}],
        out_representation: :same,
        impl: fn population, _ctx -> population end
      }

      assert_raise ArgumentError,
                   ~s/representation mismatch, "Binary crossover" does not accept {Meow.TestRepresentationSpec, :real}/,
                   fn ->
                     Algorithm.add_pipeline(
                       algorithm,
                       real_initializer,
                       Pipeline.new([real_selection, binary_crossover])
                     )
                   end
    end
  end
end
