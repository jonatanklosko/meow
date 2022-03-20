defmodule MeowNx do
  @moduledoc """
  A set of tensor representations and evolutionary operations
  to be used with the `Meow` core.

  `MeowNx` focuses on numerical performance of the underlying
  evolutionary operations. Built on top of the `Nx` library,
  it can be accelerated by using any `Nx` compiler or backend
  of choice. For instance, you can use the `EXLA` compiler to
  produce highly optimised code for your CPU or even GPU.

  `MeowNx` represents the whole population as a single tensor
  and operations are then applied to such tensor. Thanks to
  this "batched" approach (working on all individuals at once)
  we can leverage efficient tensor operations.

  `MeowNx` provides a number of numerical definitions, as well
  as `Meow` operation builders on top of that. See `MeowNx.Ops`
  for the list of available operations.

  ## Configuration

  When using `Nx` make sure to configure defn options, so that
  all numerical operations are efficiently compiled and run
  on the target platform.

  For example, to use EXLA with the CPU, add this configuration
  to the top of your script or notebook:

      Nx.Defn.global_default_options(compiler: EXLA)

  Or when targeting the GPU:

      Nx.Defn.global_default_options(
        compiler: EXLA,
        client: :cuda,
        run_options: [keep_on_device: true]
      )

  Keep in mind that your XLA compilation must support the target
  platform, which may involve setting some environment variables
  as described in [elixir-nx/xla](https://github.com/elixir-nx/xla).

  For more details on defn configuration see `Nx.Defn.global_default_options/1`.
  """

  @doc """
  Returns the real representation descriptor.
  """
  @spec real_representation() :: Meow.Population.representation()
  def real_representation(), do: {MeowNx.RepresentationSpec, :real}

  @doc """
  Returns the binary representation descriptor.
  """
  @spec binary_representation() :: Meow.Population.representation()
  def binary_representation(), do: {MeowNx.RepresentationSpec, :binary}

  @doc """
  Returns the permutation representation descriptor.
  """
  @spec permutation_representation() :: Meow.Population.representation()
  def permutation_representation(), do: {MeowNx.RepresentationSpec, :permutation}
end
