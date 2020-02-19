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

  @doc """
  Casts specific for Bundlex Api structs returned from 
  Bundlex.CNode.start/1 or Bundlex.CNode.start_link/1 to the analogous structs 
  in Unifex.UnifexCNode API or vice versa
  """
  def cast_on_start_t({:ok, %Bundlex.CNode{} = bundex_cnode}) do
    {:ok, cast_cnode(bundex_cnode)}
  end

  def cast_on_start_t({:ok, %__MODULE__{} = unifex_cnode}) do
    {:ok, cast_cnode(unifex_cnode)}
  end

  def cast_on_start_t(on_start) do
    on_start
  end

  @doc """
  Casts Bundlex.CNode struct to Unifex.UnifexCNode struct or vice versa
  """
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
  Spawns specific CNode and links to it
  """
  defmacro start_link(native_name) do
    quote do
      require Bundlex.CNode

      unquote(native_name)
      |> Bundlex.CNode.start_link()
      |> unquote(__MODULE__).cast_on_start_t
    end
  end

  @doc """
  Spawns specific CNode, but without linking.
  """
  defmacro start(native_name) do
    quote do
      require Bundlex.CNode

      unquote(native_name)
      |> Bundlex.CNode.start()
      |> unquote(__MODULE__).cast_on_start_t
    end
  end

  @doc """
  Disconnects from CNode.
  """
  @spec stop(t) :: :ok | {:error, :disconnect_cnode}
  def stop(%__MODULE__{} = unifex_cnode) do
    unifex_cnode
    |> cast_cnode
    |> Bundlex.CNode.stop()
  end

  @doc """
  Starts monitoring CNode from the calling process.
  """
  @spec monitor(t) :: reference
  def monitor(%__MODULE__{} = unifex_cnode) do
    unifex_cnode
    |> cast_cnode
    |> Bundlex.CNode.monitor()
  end

  @doc """
  Sends to CNode serialized 'message'
  """
  @spec send(t, message :: term) :: :ok
  def send(%__MODULE__{} = unifex_cnode, message) do
    unifex_cnode
    |> cast_cnode
    |> Bundlex.CNode.send(message)
  end


  defp unpack_result({:result, content}) do
    content
  end

  @doc """
  Makes a synchronous call to CNode and waits for its reply.

  If the response doesn't come in within `timeout`, error is raised.
  Messages are exchanged directly (without interacting with CNode's associated
  server).
  """
  @spec call(t, fun_name :: atom, args :: list, timeout :: non_neg_integer | :infinity) ::
          response :: term
  def call(%__MODULE__{} = unifex_cnode, fun_name, args \\ [], timeout \\ 5000) do
    msg = [fun_name | args] |> List.to_tuple()

    unifex_cnode
    |> cast_cnode
    |> Bundlex.CNode.call(msg, timeout)
    |> case do
      {:result, _content} = response ->
        response |> unpack_result

      {:error, _reason} = response ->
        response
    end
  end

  @doc """
  Invokes call of given function, but doesn't return result. Call Unifex.UnifexCNode.receive_result/2, to get returned value
  """
  @spec cast(t, fun_name :: atom, args :: list) :: :ok
  def cast(%__MODULE__{} = unifex_cnode, fun_name, args \\ []) do
    msg = [fun_name | args] |> List.to_tuple()

    unifex_cnode
    |> cast_cnode
    |> Bundlex.CNode.send(msg)
  end

  @doc """
      Waits timeout miliseconds on result returned from remote call of remote UnifexCNode function.
      Generally, when function only returns values and don't send any messages, consider use of UnifexCNode.call/3, instead of this one
  """
  @spec receive_result(t, timeout :: non_neg_integer | :infinity) ::
          response :: term | {:error, :time_left}
  def receive_result(%__MODULE__{node: node}, timeout \\ 5000) do
    receive do
      {^node, {:result, _content} = response} ->
        response |> unpack_result

      {^node, {:error, _reason} = response} ->
        response
    after
      timeout -> {:error, :time_left}
    end
  end
end
