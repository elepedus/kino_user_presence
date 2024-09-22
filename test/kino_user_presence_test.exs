defmodule KinoUserPresenceTest do
  use ExUnit.Case
  doctest KinoUserPresence
  alias Kino.JS.Live.Context

  setup do
    on_join = fn origin -> send(self(), {:user_joined, origin}) end
    on_leave = fn origin -> send(self(), {:user_left, origin}) end
    {:ok, on_join: on_join, on_leave: on_leave}
  end

  test "listen/2 returns a Kino.JS.Live struct" do
    result = KinoUserPresence.listen(fn _ -> nil end, fn _ -> nil end)
    assert %Kino.JS.Live{} = result
  end

  test "init/2 initializes the context correctly", %{on_join: on_join, on_leave: on_leave} do
    {:ok, ctx} = KinoUserPresence.init(%{join: on_join, leave: on_leave}, Context.new())
    assert ctx.assigns.callbacks.join == on_join
    assert ctx.assigns.callbacks.leave == on_leave
    assert ctx.assigns.users == %{}
  end

  test "handle_connect/1 adds a new user and calls the join callback", %{
    on_join: on_join,
    on_leave: on_leave
  } do
    ctx =
      Context.new() |> Context.assign(callbacks: %{join: on_join, leave: on_leave}, users: %{})

    {:ok, nil, new_ctx} = KinoUserPresence.handle_connect(ctx)

    assert map_size(new_ctx.assigns.users) == 1
    assert_received {:user_joined, _}
  end

  test "handle_event(\"pong\") updates the last_seen timestamp" do
    ctx =
      Context.new()
      |> Context.assign(
        users: %{
          "origin" => %{
            last_seen: ~U[2023-01-01 00:00:00Z]
          }
        }
      )

    {:noreply, result} = KinoUserPresence.handle_event("pong", "origin", ctx)
    new_timestamp = result.assigns.users["origin"].last_seen

    assert new_timestamp != ~U[2023-01-01 00:00:00Z]
    assert DateTime.compare(new_timestamp, ~U[2023-01-01 00:00:00Z]) == :gt
  end

  test "handle_info({:check_timestamp, origin}) removes inactive user", %{
    on_join: on_join,
    on_leave: on_leave
  } do
    old_timestamp = DateTime.add(DateTime.utc_now(), -1000, :millisecond)

    ctx =
      Context.new()
      |> Context.assign(
        callbacks: %{join: on_join, leave: on_leave},
        users: %{"inactive_user" => %{last_seen: old_timestamp}}
      )

    {:noreply, new_ctx} = KinoUserPresence.handle_info({:check_timestamp, "inactive_user"}, ctx)

    assert new_ctx.assigns.users == %{}
    assert_received {:user_left, "inactive_user"}
  end

  test "handle_info({:check_timestamp, origin}) keeps active user" do
    ctx =
      Context.new()
      |> Context.assign(
        callbacks: %{join: fn _ -> nil end, leave: fn _ -> nil end},
        users: %{"active_user" => %{last_seen: DateTime.utc_now()}}
      )

    {:noreply, new_ctx} = KinoUserPresence.handle_info({:check_timestamp, "active_user"}, ctx)

    assert map_size(new_ctx.assigns.users) == 1
    assert Map.has_key?(new_ctx.assigns.users, "active_user")
  end
end
