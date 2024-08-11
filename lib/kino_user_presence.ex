defmodule KinoUserPresence do
  @moduledoc """
  A module for tracking user presence in Kino applications.

  This module provides functionality to monitor user connections, track their
  activity through heartbeats, and execute callbacks when users join or leave.
  It uses Kino.JS.Live for real-time communication with clients.
  """

  @heartbeat_interval 100
  @grace 3
  use Kino.JS
  use Kino.JS.Live

  @doc """
  Initializes a new user presence tracker.

  ## Parameters

  - `on_join`: A function to be called when a user joins. It receives the user's origin as an argument.
  - `on_leave`: A function to be called when a user leaves. It receives the user's origin as an argument.

  ## Returns

  A new Kino.JS.Live struct configured for user presence tracking.

  ## Example

      KinoUserPresence.listen(
        &IO.puts/1,
        &IO.puts/1,
      )
  """
  def listen(on_join, on_leave),
      do: Kino.JS.Live.new(__MODULE__, %{join: on_join, leave: on_leave})

  @impl true
  def init(callbacks, ctx) do
    {:ok, assign(ctx, callbacks: callbacks, users: %{})}
  end

  @impl true
  def handle_connect(ctx) do
    users =
      ctx.assigns.users
      |> Map.put_new(ctx.origin, %{last_seen: DateTime.utc_now()})

    apply(ctx.assigns.callbacks.join, [ctx.origin])
    Process.send_after(self(), {:check_heartbeat, ctx.origin}, @heartbeat_interval)
    {:ok, nil, assign(ctx, users: users)}
  end

  @impl true
  def handle_info({:check_heartbeat, origin}, ctx) do
    Kino.JS.Live.Context.send_event(ctx, origin, "ping", origin)
    Process.send_after(self(), {:check_timestamp, origin}, @heartbeat_interval)
    {:noreply, ctx}
  end

  @impl true
  def handle_info({:check_timestamp, origin}, %{assigns: assigns} = ctx) do
    timestamp = get_in(assigns, [:users, origin, :last_seen])

    if DateTime.diff(DateTime.utc_now(), timestamp, :millisecond) > @heartbeat_interval * @grace do
      users = Map.reject(assigns.users, fn {k, _v} -> k == origin end)
      apply(ctx.assigns.callbacks.leave, [origin])
      {:noreply, assign(ctx, users: users)}
    else
      Process.send_after(self(), {:check_heartbeat, origin}, @heartbeat_interval)
      {:noreply, ctx}
    end
  end

  @impl true
  def handle_event("pong", payload, ctx) do
    users =
      ctx.assigns.users
      |> Map.update!(payload, fn map ->
        Map.update!(map, :last_seen, fn _ -> DateTime.utc_now() end)
      end)

    {:noreply, assign(ctx, users: users)}
  end

  asset "main.js" do
    """
    export function init(ctx, blah) {
      ctx.handleEvent("ping", (data) => {
        ctx.pushEvent("pong", data);
      })
    }
    """
  end
end