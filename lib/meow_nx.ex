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

  `MeowNx` provides a number of numerical definitions,
  as well as `Meow` operation definitions on top of that.
  """
end
