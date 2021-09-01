defmodule Meow.Distribution do
  @moduledoc """
  Utilities for setting up and connecting runtime nodes.

  When running the computation as a script you can use
  `init_from_cli_args!/1` to easily configure the
  distribution based on the CLI arguments. Otherwise the
  underlying `init_leader/2` and `init_worker/1` are also
  available.

  Note that this module only provides conveniences and
  configuration patterns, but you are free to setup and
  connect the runtime nodes however you see fit. The core
  APIs expect all relevant nodes to be already connected
  and are agnostic to how it actually happens.
  """

  require Logger

  @doc """
  Initializes the runtime node based on the command line arguments.

  Make sure to start the runtime in Erlang ditribution mode
  by specifying node name.

  Supports two combinations of arguments:

    * `leader [worker_node] [worker_node] ...` - in this mode
      the process establishes connection between all of the
      listed worker nodes and then calls `leader_fun` passing
      all nodes (including the leader) as an argument.

    * `worker` - in this mode the process waits for the leader
      to initiate the connection and start the relevant work.
      The worker terminates as soon as the leader node terminates.

  ## Options

    * `:leader_opts` - see `init_leader/2` for available options

    * `:worker_opts` - see `init_worker/1` for available options

  ## Example

  Start the leader node:

      $ elixir --name leader@127.0.0.1 script.exs leader worker1@127.0.0.1 worker2@127.0.0.1

  Start the worker nodes:

      $ elixir --name worker1@127.0.0.1 script.exs worker

      $ elixir --name worker2@127.0.0.1 script.exs worker

  Where `script.exs` calls this function:

      Meow.Distribution.init_from_cli_args!(fn nodes ->
        # This runs on the leader node, once it successfully
        # connects to all worker nodes
      end)
  """
  @spec init_from_cli_args!((list(node()) -> any()), keyword()) :: :ok
  def init_from_cli_args!(leader_fun, opts \\ []) do
    validate_distribution!()

    case System.argv() do
      ["leader" | worker_nodes] ->
        worker_nodes = Enum.map(worker_nodes, &String.to_atom/1)

        leader_opts = opts[:leader_opts] || []
        Meow.Distribution.init_leader(worker_nodes, leader_opts)

        leader_fun.([node() | worker_nodes])

      ["worker"] ->
        worker_opts = opts[:worker_opts] || []
        Meow.Distribution.init_worker(worker_opts)

      args ->
        raise RuntimeError, """
        got unexpected CLI arguments: #{inspect(args)}

        Expected one of the following:

          leader [worker_node] [worker_node] ...

          worker

        See the documentation for more usage details\
        """
    end
  end

  @doc """
  Enters leader mode.

  Establishes connection to all of the given nodes and initiates
  communication.

  ## Options

    * `:max_attempts` - the maximum number of connection attempts
      to each node. Defaults to `60`.

    * `:attempt_gap` - the number of milliseconds between
      subsequent connection attempts. Defaults to `1_000`.
  """
  @spec init_leader(list(node()), keyword()) :: :ok
  def init_leader(worker_nodes, opts \\ []) do
    validate_distribution!()

    max_attempts = opts[:max_attempts] || 60
    attempt_gap = opts[:attempt_gap] || 1_000

    initiate_workers(worker_nodes, [], max_attempts, attempt_gap)

    Logger.info("Established connection with all worker nodes")

    :ok
  end

  # Each node starts as disconnected, upon connection it
  # becomes uninitiated, finally once we locate the worker
  # process and send the init message it becomes initiated
  defp initiate_workers(disconnected, uninitiated, attempts_left, attempt_gap)

  defp initiate_workers(disconnected, uninitiated, 0, _attempt_gap) do
    message =
      [
        "failed to establish connection to all worker within the given time limit",
        if disconnected != [] do
          "  * could not connect to the following nodes: #{Enum.join(disconnected, ", ")}"
        end,
        if uninitiated != [] do
          "  * no worker process found on the following nodes: #{Enum.join(uninitiated, ", ")}"
        end
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n\n")

    raise RuntimeError, message
  end

  defp initiate_workers(disconnected, uninitiated, attempts, attempt_gap) do
    {new_connected, disconnected} = Enum.split_with(disconnected, &Node.connect/1)

    {ready, uninitiated} =
      Enum.split_with(new_connected ++ uninitiated, fn node ->
        :global.whereis_name({node, :worker}) != :undefined
      end)

    for node <- ready do
      :global.send({node, :worker}, {:initiate, node()})
    end

    if disconnected == [] and uninitiated == [] do
      :ok
    else
      Process.sleep(attempt_gap)
      initiate_workers(disconnected, uninitiated, attempts - 1, attempt_gap)
    end
  end

  @doc """
  Enters worker mode.

  Waits for the leader node to initiate a connection, then
  starts monitoring this node and blocks until it terminates.

  Raises `RuntimeError` if the initial message is not received
  within the optional timeout.

  ## Options

    * `:timeout` - the maximum number of milliseconds to wait
      for the leader node to initiate the connection. Defaults
      to `60_000`.
  """
  @spec init_worker(keyword()) :: :ok
  def init_worker(opts \\ []) do
    validate_distribution!()

    timeout = opts[:timeout] || 60_000

    :global.register_name({node(), :worker}, self())

    receive do
      {:initiate, leader_node} ->
        Logger.info("Established connection with the leader node (#{leader_node})")

        Node.monitor(leader_node, true)

        receive do
          {:nodedown, ^leader_node} -> :ok
        end
    after
      timeout ->
        raise RuntimeError,
              "expected to receive an initial message from the leader node within #{timeout}ms, but got none"
    end
  end

  defp validate_distribution!() do
    unless Node.alive?() do
      raise RuntimeError,
            "distribution mode hasn't been enabled, make sure to specify a node name when starting the runtime"
    end
  end
end
