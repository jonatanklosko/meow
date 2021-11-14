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
  """

  # TODO: the JIT configuration may no longer be necessary once Nx makes
  # the options globally configurable, see https://github.com/elixir-nx/nx/issues/506

  @doc """
  Configures the options passed to `Nx.Defn.jit/3` when compiling
  numerical operations.
  """
  @spec configure_jit_opts(keyword()) :: :ok
  def configure_jit_opts(opts) when is_list(opts) do
    Application.put_env(:meow_nx, :jit_opts, opts)
  end

  defp jit_opts() do
    cond do
      opts = Application.get_env(:meow_nx, :jit_opts) -> opts
      Code.ensure_loaded?(EXLA) -> [compiler: EXLA]
      true -> []
    end
  end

  @doc """
  Compiles and invokes the given numerical function.

  Use this function when extending `MeowNx` with custom operations.
  For examples see the source code of `MeowNx.Ops`.

  This is a wrapper around `Nx.Defn.jit/3` that does two additional
  things:

    * uses the JIT options configured with `configure_jit_opts/1`.
      If no options have been configured and `exla` is available
      defaults to `[compiler: EXLA]` and `[]` otherwise

    * supports options and tensor lists in the argument list, which
      ensures the usage is akin to `apply/2`

  ## Examples

      MeowNx.jit(&Mod.operation/2, [genomes, opts])
  """
  def jit(fun, args) do
    # Split arguments into tensors that we actually pass to JIT
    # and options that we access directly in the function wrapper
    {infos, {tensor_map, opts_map}} =
      args
      |> Enum.with_index()
      |> Enum.map_reduce({%{}, %{}}, fn {arg, i}, {tensor_map, opts_map} ->
        cond do
          is_list(arg) and Enum.all?(arg, &tensor_like?/1) ->
            # Nx.Defn.jit/3 doesn't allow tensor list in arguments, so we convert it to tuple
            {{:tensor_list, i}, {put_in(tensor_map[i], List.to_tuple(arg)), opts_map}}

          Keyword.keyword?(arg) ->
            {{:opts, i}, {tensor_map, put_in(opts_map[i], arg)}}

          arg ->
            {{:tensor, i}, {put_in(tensor_map[i], arg), opts_map}}
        end
      end)

    fun_wrapper = fn tensor_map ->
      args =
        Enum.map(infos, fn
          {:tensor_list, i} -> Tuple.to_list(tensor_map[i])
          {:opts, i} -> opts_map[i]
          {:tensor, i} -> tensor_map[i]
        end)

      apply(fun, args)
    end

    Nx.Defn.jit(fun_wrapper, [tensor_map], jit_opts())
  end

  defp tensor_like?(%Nx.Tensor{}), do: true
  defp tensor_like?(n) when is_number(n), do: true
  defp tensor_like?(_), do: false

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
end
