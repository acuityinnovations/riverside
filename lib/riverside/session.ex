defmodule Riverside.Session do

  @abbreviation_header "Session"
  @session_id_length 20

  alias Riverside.IO.Random
  alias Riverside.Session.MessageCounter

  @type t :: %__MODULE__{user_id:         non_neg_integer,
                         id:              String.t,
                         abbreviation:    String.t,
                         message_counter: MessageCounter.t,
                         peer:            PeerInfo.t,
                         trapping_pids:   MapSet.t}

  defstruct user_id:         0,
            id:              "",
            abbreviation:    "",
            message_counter: nil,
            peer:            nil,
            trapping_pids:   nil

  def new(user_id, peer) do

    session_id = create_session_id()
    abbreviation = create_abbreviation(user_id, session_id)

    %__MODULE__{user_id:         user_id,
                id:              session_id,
                abbreviation:    abbreviation,
                message_counter: MessageCounter.new(),
                trapping_pids:   MapSet.new(),
                peer:            peer}
  end

  defp create_session_id() do
    Random.hex(@session_id_length)
  end

  defp create_abbreviation(user_id, session_id) do
    "<#{@abbreviation_header}:#{user_id}:#{String.slice(session_id, 0..5)}>"
  end

  @spec should_delegate_exit?(t, pid) :: boolean

  def should_delegate_exit?(state, pid) do
    MapSet.member?(state.trapping_pids.member, pid)
  end

  @spec trap_exit(t, pid) :: t

  def trap_exit(%{trapping_pids: pids}=state, pid) do
    %{state |trapping_pids: MapSet.put(pids, pid)}
  end

  @spec forget_to_trap_exit(t, pid) :: t

  def forget_to_trap_exit(%{trapping_pids: pids}=state, pid) do
    %{state |trapping_pids: MapSet.delete(pids, pid)}
  end

  @spec countup_messages(t) :: {:ok, t}
    | {:error, :too_many_messages}

  def countup_messages(%{message_counter: counter}=state) do
    case MessageCounter.countup(counter) do

      {:ok, counter} ->
        {:ok, %{state|message_counter: counter}}

      {:error, :too_many_messages} ->
        {:error, :too_many_messages}
    end
  end

  def peer_address(%__MODULE__{peer: peer}) do
    "#{peer}"
  end

end

defimpl String.Chars, for: Riverside.Session do

  alias Riverside.Session

  def to_string(%Session{abbreviation: abbreviation}) do
    abbreviation
  end

end