defmodule Anchorage.RoomSession do
  use GenServer, restart: :temporary

  defmodule State do
    defimpl Jason.Encoder, for: State do
      def encode(value, opts) do
        to_encode =
          value
          |> Map.from_struct()
          |> Enum.map(fn {key, value} -> {transform_key(key), value} end)
          |> Enum.into(%{})

        Jason.Encode.map(Map.take(to_encode, [:id, :name, :code, :isPrivate, :game]), opts)
      end

      @spec transform_key(atom()) :: atom()
      defp transform_key(old_key) do
        case old_key do
          :room_id -> :id
          :room_creator_id -> :creatorId
          :room_name -> :name
          :room_code -> :code
          :is_private -> :isPrivate
          x -> x
        end
      end
    end

    @type t :: %__MODULE__{
            room_id: String.t(),
            room_creator_id: String.t(),
            room_name: String.t(),
            room_code: String.t(),
            is_private: String.t(),
            users: [String.t()],
            game: atom()
          }

    defstruct room_id: "",
              room_creator_id: "",
              room_name: "",
              room_code: "",
              is_private: false,
              users: [],
              game: :none
  end

  defp via(user_id), do: {:via, Registry, {Anchorage.RoomSessionRegistry, user_id}}

  defp cast(user_id, params), do: GenServer.cast(via(user_id), params)
  defp call(user_id, params), do: GenServer.call(via(user_id), params)

  def start_supervised(initial_values) do
    case DynamicSupervisor.start_child(
           Anchorage.RoomSessionDynamicSupervisor,
           {__MODULE__, initial_values}
         ) do
      {:error, {:already_started, pid}} -> {:ignored, pid}
      error -> error
    end
  end

  def child_spec(init), do: %{super(init) | id: Keyword.get(init, :room_id)}

  def count, do: Registry.count(Anchorage.RoomSessionRegistry)
  def lookup(room_id), do: Registry.lookup(Anchorage.RoomSessionRegistry, room_id)

  def start_link(init) do
    GenServer.start_link(__MODULE__, init, name: via(init[:room_id]))
  end

  def init(init) do
    Anchorage.Chat.start_link_supervised(init)
    {:ok, struct(State, init)}
  end

  def ws_fan(users, msg) do
    Enum.each(users, fn uid ->
      Anchorage.UserSession.send_ws(uid, nil, msg)
    end)
  end

  ### - API - #########################################################################

  def get_state(room_id) do
    call(room_id, {:get_state})
  end

  defp get_state_impl(state) do
    {:reply, state, state}
  end

  def join_room(room_id, user_id, opts \\ []) do
    cast(room_id, {:join_room, user_id, opts})
  end

  defp join_room_impl(user_id, opts, state) do
    Anchorage.Chat.add_user(state.room_id, user_id)

    user = Anchorage.UserSession.get_state(user_id)

    Anchorage.UserSession.set_current_room_id(user_id, state.room_id)

    if not is_nil(user) do
      unless opts[:no_fan] do
        ws_fan(state.users, %{
          op: "user_join",
          d: %{
            user: user
          }
        })
      end
    end

    IO.puts("user joined room")

    {:noreply,
     %{
       state
       | users: [
           user_id
           | Enum.filter(state.users, fn uid -> uid != user_id end)
         ]
     }}
  end

  def leave_room(room_id, user_id), do: cast(room_id, {:leave_room, user_id})

  defp leave_room_impl(user_id, state) do
    users = Enum.reject(state.users, &(&1 == user_id))

    ws_fan(users, %{
      op: "user_left_room",
      d: %{userId: user_id, roomId: state.room_id}
    })

    {:noreply, state}
  end

  ### - ROUTER - ######################################################################

  def handle_call({:get_state}, _reply, state), do: get_state_impl(state)

  def handle_cast({:join_room, user_id, opts}, state), do: join_room_impl(user_id, opts, state)
  def handle_cast({:leave_room, user_id}, state), do: leave_room_impl(user_id, state)
end
