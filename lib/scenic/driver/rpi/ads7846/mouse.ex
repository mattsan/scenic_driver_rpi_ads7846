defmodule Scenic.Driver.Rpi.ADS7846.Mouse do
  @moduledoc false

  require Logger

  def simulate(state, events) do
    Enum.reduce(events, state, fn
      {:ev_key, :btn_touch, 0}, %{touch: false} = state ->
        %{state | mouse_event: nil}

      {:ev_key, :btn_touch, 1}, %{touch: false} = state ->
        %{state | touch: true, mouse_event: :mouse_down}

      {:ev_key, :btn_touch, 0}, %{touch: true} = state ->
        %{state | touch: false, mouse_event: :mouse_up}

      {:ev_key, :btn_touch, 1}, %{touch: true} = state ->
        %{state | mouse_event: nil}

      {:ev_abs, :abs_x, x}, %{slot: 0, mouse_event: nil} = state ->
        %{state | mouse_event: :mouse_move, mouse_x: x}

      {:ev_abs, :abs_y, y}, %{slot: 0, mouse_event: nil} = state ->
        %{state | mouse_event: :mouse_move, mouse_y: y}

      {:ev_abs, :abs_x, x}, %{slot: 0} = state ->
        %{state | mouse_x: x}

      {:ev_abs, :abs_y, y}, %{slot: 0} = state ->
        %{state | mouse_y: y}

      _, state ->
        state
    end)
  end

  def update_event(state) do
    case state do
      %{mouse_event: :mouse_down, mouse_x: x, mouse_y: y} ->
        point = project_point(state, {x, y})
        input_event = {:cursor_button, {:left, :press, 0, point}}
        {%{state | mouse_event: nil}, input_event}

      %{mouse_event: :mouse_up, mouse_x: x, mouse_y: y} ->
        point = project_point(state, {x, y})
        input_event = {:cursor_button, {:left, :release, 0, point}}
        {%{state | mouse_event: nil, mouse_x: nil, mouse_y: nil}, input_event}

      %{mouse_event: :mouse_move, mouse_x: x, mouse_y: y} ->
        point = project_point(state, {x, y})
        input_event = {:cursor_pos, point}
        {%{state | mouse_event: nil}, input_event}

      _ ->
        {state, :no_input_event}
    end
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
