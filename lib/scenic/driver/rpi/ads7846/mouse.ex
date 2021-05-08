defmodule Scenic.Driver.Rpi.ADS7846.Mouse do
  @moduledoc false

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

  def get_input_event(state) do
    case state do
      %{mouse_event: :mouse_down} ->
        {
          %{state | mouse_event: nil},
          {:cursor_button, {:left, :press, 0, get_screen_point(state)}}
        }

      %{mouse_event: :mouse_up} ->
        {
          %{state | mouse_event: nil, mouse_x: nil, mouse_y: nil},
          {:cursor_button, {:left, :release, 0, get_screen_point(state)}}
        }

      %{mouse_event: :mouse_move} ->
        {
          %{state | mouse_event: nil},
          {:cursor_pos, get_screen_point(state)}
        }

      _ ->
        {
          state,
          :no_input_event
        }
    end
  end

  defp get_screen_point(%{mouse_x: x, mouse_y: y} = state) do
    {x, y}
    |> calibrate(state)
    |> transform(state)
  end

  defp calibrate({x, y}, state) do
    case state do
      %{calibration: {{ax, bx, dx}, {ay, by, dy}}} ->
        {
          x * ax + y * bx + dx,
          y * ay + x * by + dy
        }

      _ ->
        {x, y}
    end
  end

  defp transform({x, y}, state) do
    case state do
      %{rotate: 0, size: {width, height}} ->
        {width - y, height - x}

      %{rotate: 1, size: {width, _}} ->
        {width - x, y}

      %{rotate: 2} ->
        {y, x}

      %{rotate: 3, size: {_, height}} ->
        {x, height - y}

      _ ->
        {x, y}
    end
  end
end
