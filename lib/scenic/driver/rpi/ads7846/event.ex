defmodule Scenic.Driver.Rpi.ADS7846.Event do
  @moduledoc false

  require Logger

  defguardp is_point(x, y) when is_number(x) and is_number(y)

  def simulate(state, events) do
    Enum.reduce(events, state, fn event, state ->
      state
      |> simulate_button(event)
      |> simulate_movinig(event)
    end)
  end

  defp simulate_button(state, event) do
    case {state, event} do
      {%{touch: touch}, {:ev_key, :btn_touch, 1}} ->
        mouse_event =
          case touch do
            true -> nil
            false -> :mouse_down
          end

        %{state | touch: true, mouse_event: mouse_event}

      {%{touch: touch}, {:ev_key, :btn_touch, 0}} ->
        mouse_event =
          case touch do
            true -> :mouse_up
            false -> nil
          end

        %{state | touch: false, mouse_event: mouse_event}

      {state, _event} ->
        state
    end
  end

  defp simulate_movinig(state, event) do
    case {state, event} do
      {%{slot: 0, mouse_event: nil}, {:ev_abs, :abs_x, x}} ->
        %{state | mouse_event: :mouse_move, mouse_x: x}

      {%{slot: 0, mouse_event: nil} = state, {:ev_abs, :abs_y, y}} ->
        %{state | mouse_event: :mouse_move, mouse_y: y}

      {%{slot: 0} = state, {:ev_abs, :abs_x, x}} ->
        %{state | mouse_x: x}

      {%{slot: 0} = state, {:ev_abs, :abs_y, y}} ->
        %{state | mouse_y: y}

      {state, _} ->
        state
    end
  end

  def send_event(state, f)

  def send_event(%{mouse_x: x, mouse_y: y, mouse_event: :mouse_down} = state, f)
      when is_point(x, y) and is_function(f) do
    point = project_point(state, {x, y})
    input_event = {:cursor_button, {:left, :press, 0, point}}

    Logger.debug("input_event: #{inspect(input_event, limit: :infinity)}")

    f.(input_event)

    %{state | mouse_event: nil}
  end

  def send_event(%{mouse_x: x, mouse_y: y, mouse_event: :mouse_up} = state, f)
      when is_point(x, y) and is_function(f) do
    point = project_point(state, {x, y})
    input_event = {:cursor_button, {:left, :release, 0, point}}

    Logger.debug("input_event: #{inspect(input_event, limit: :infinity)}")

    f.(input_event)

    %{state | mouse_x: nil, mouse_y: nil, mouse_event: nil}
  end

  def send_event(%{mouse_x: x, mouse_y: y, mouse_event: :mouse_move} = state, f)
      when is_point(x, y) and is_function(f) do
    point = project_point(state, {x, y})
    input_event = {:cursor_pos, point}

    Logger.debug("input_event: #{inspect(input_event, limit: :infinity)}")

    f.(input_event)

    %{state | mouse_event: nil}
  end

  def send_event(%{mouse_event: :mouse_up} = state, f) when is_function(f) do
    %{state | mouse_x: nil, mouse_y: nil, mouse_event: nil}
  end

  def send_event(state, _f) do
    state
  end

  defp project_point(%{calibration: {{ax, bx, dx}, {ay, by, dy}}} = state, {x, y}) do
    point = {
      x * ax + y * bx + dx,
      y * ay + x * by + dy
    }

    transform(state, point)
  end

  defp project_point(state, {_, _} = point) do
    transform(state, point)
  end

  defp transform(%{rotate: 0, size: {width, height}}, {x, y}), do: {width - y, height - x}
  defp transform(%{rotate: 1, size: {width, _}}, {x, y}), do: {width - x, y}
  defp transform(%{rotate: 2}, {x, y}), do: {y, x}
  defp transform(%{rotate: 3, size: {_, height}}, {x, y}), do: {x, height - y}
  defp transform(_, {x, y}), do: {x, y}
end
