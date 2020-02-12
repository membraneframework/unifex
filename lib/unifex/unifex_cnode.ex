defmodule Unifex.UnifexCNode do
  @doc """
  Wraps Bundlex.CNode functionalities, in due to support specific Unifex's CNode behaviours
  """

  require Bundlex.CNode

  @enforce_keys [:server, :node]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          server: pid,
          node: node
        }

  @type on_start_t :: {:ok, t} | {:error, :spawn_cnode | :connect_to_cnode}

  def cast_on_start_t({:ok, %Bundlex.CNode{} = bundex_cnode}) do
    {:ok, cast_cnode(bundex_cnode)}
  end

  def cast_on_start_t({:ok, %__MODULE__{} = unifex_cnode}) do
    {:ok, cast_cnode(unifex_cnode)}
  end

  def cast_on_start_t(on_start) do
    on_start
  end

  def cast_cnode(%Bundlex.CNode{server: server, node: node}) do
    %__MODULE__{
      server: server,
      node: node
    }
  end

  def cast_cnode(%__MODULE__{server: server, node: node}) do
    %Bundlex.CNode{
      server: server,
      node: node
    }
  end

  @doc """
  Calls Bundlex.CNode functions.
  Look at Bundlex.CNode docs, to see more.
  """

  defmacro start_link(native_name) do
    quote do
      require Bundlex.CNode

      unquote(native_name)
      |> Bundlex.CNode.start_link()
      |> unquote(__MODULE__).cast_on_start_t
    end
  end

  defmacro start(native_name) do
    quote do
      require Bundlex.CNode

      unquote(native_name)
      |> Bundlex.CNode.start()
      |> unquote(__MODULE__).cast_on_start_t
    end
  end

  @spec stop(t) :: :ok | {:error, :disconnect_cnode}
  def stop(%__MODULE__{} = unifex_cnode) do
    unifex_cnode
    |> cast_cnode
    |> Bundlex.CNode.stop()
  end

  @spec monitor(t) :: reference
  def monitor(%__MODULE__{} = unifex_cnode) do
    unifex_cnode
    |> cast_cnode
    |> Bundlex.CNode.monitor()
  end

  @spec send(t, message :: term) :: :ok
  def send(%__MODULE__{} = unifex_cnode, message) do
    unifex_cnode
    |> cast_cnode
    |> Bundlex.CNode.send(message)
  end

  def unpack_result({:result, content}) do
    content
  end

  def unpack_message({:send, content}) do
    content
  end

  @doc """
      Sends to CNode message containing data about which function should be called and with which args,
      then waits timeout miliseconds to receive and unpack function result
  """
  @spec remote_call(t, fun_name :: atom, args :: list, timeout :: non_neg_integer | :infinity) ::
          response :: term
  def remote_call(%__MODULE__{} = unifex_cnode, fun_name, args \\ [], timeout \\ 5000) do
    msg = [fun_name | args] |> List.to_tuple()

    unifex_cnode
    |> cast_cnode
    |> Bundlex.CNode.call(msg, timeout)
    |> case do
      {:result, content} = response ->
        response |> unpack_result

      {:error, reason} = response ->
        response
    end
  end

  @doc """
      Sends to CNode message containing data about which function should be called and with which args,
      but don't wait on any message back.
      
      Should be used, when called CNode function sends messages (look at .spec.exs), instead of return value
  """
  @spec start_running(t, fun_name :: atom, args :: list) :: :ok
  def start_running(%__MODULE__{} = unifex_cnode, fun_name, args \\ []) do
    msg = [fun_name | args] |> List.to_tuple()

    unifex_cnode
    |> cast_cnode
    |> Bundlex.CNode.send(msg)
  end

  @doc """
      Waits timeout miliseconds on message sent from specific UnifexCNode.
  """
  @spec receive_msg(t, timeout :: non_neg_integer | :infinity) ::
          response :: term | {:error, :time_left}
  def receive_msg(%__MODULE__{node: node}, timeout \\ 5000) do
    receive do
      {^node, {:send, content} = response} ->
        response |> unpack_message

      {^node, {:error, reason} = response} ->
        response
    after
      timeout -> {:error, :time_left}
    end
  end

  @doc """
      Waits timeout miliseconds on result returned from remote call of remote UnifexCNode function.
      Generally, when function only returns values and don't send any messages, consider use of UnifexCNode.remote_call, instead of this one
  """
  @spec receive_result(t, timeout :: non_neg_integer | :infinity) ::
          response :: term | {:error, :time_left}
  def receive_result(%__MODULE__{node: node}, timeout \\ 5000) do
    receive do
      {^node, {:result, content} = response} ->
        response |> unpack_result

      {^node, {:error, reason} = response} ->
        response
    after
      timeout -> {:error, :time_left}
    end
  end
end
