defmodule Scenic.Driver.Rpi.ADS7846.Mouse do
  @moduledoc false

  alias Scenic.ViewPort

  require Logger

  defguardp is_pos(x, y) when is_number(x) and is_number(y)

  def ev_abs(state, event) do
    case {state, event} do
      {%{touch: touch}, {:ev_key, :btn_touch, 1}} ->
        mouse_event = if touch, do: nil, else: :mouse_down
        %{state | touch: true, mouse_event: mouse_event}

      {%{touch: touch}, {:ev_key, :btn_touch, 0}} ->
        mouse_event = if touch, do: :mouse_up, else: nil
        %{state | touch: false, mouse_event: mouse_event}

      {state, _event} ->
        state
    end
  end

  def simulate_mouse(state, event) do
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

  def send_mouse(state)

  def send_mouse(%{viewport: viewport, mouse_x: x, mouse_y: y, mouse_event: :mouse_down} = state)
      when is_pos(x, y) do
    pos = project_pos({x, y}, state)

    Logger.debug(
      "ViewPort.input(#{inspect(viewport)}, {:cursor_button, {:left, :press, 0, #{inspect(pos)}}})"
    )

    ViewPort.input(viewport, {:cursor_button, {:left, :press, 0, pos}})

    %{state | mouse_event: nil}
  end

  def send_mouse(%{viewport: viewport, mouse_x: x, mouse_y: y, mouse_event: :mouse_up} = state)
      when is_pos(x, y) do
    pos = project_pos({x, y}, state)

    Logger.debug(
      "ViewPort.input(#{inspect(viewport)}, {:cursor_button, {:left, :release, 0, #{inspect(pos)}}})"
    )

    ViewPort.input(viewport, {:cursor_button, {:left, :release, 0, pos}})

    %{state | mouse_x: nil, mouse_y: nil, mouse_event: nil}
  end

  def send_mouse(%{viewport: viewport, mouse_x: x, mouse_y: y, mouse_event: :mouse_move} = state)
      when is_pos(x, y) do
    pos = project_pos({x, y}, state)

    Logger.debug("ViewPort.input(#{inspect(viewport)}, {:cursor_pos, #{inspect(pos)}})")

    ViewPort.input(viewport, {:cursor_pos, pos})

    %{state | mouse_event: nil}
  end

  def send_mouse(%{mouse_event: :mouse_up} = state) do
    %{state | mouse_x: nil, mouse_y: nil, mouse_event: nil}
  end

  def send_mouse(state) do
    state
  end

  defp project_pos({x, y}, %{calibration: {{ax, bx, dx}, {ay, by, dy}}}) do
    {
      x * ax + y * bx + dx,
      y * ay + x * by + dy
    }
    |> transpose()
  end

  defp project_pos(pos, _) do
    pos
    |> transpose()
  end

  defp transpose({x, y}) do
    {y, x}
  end
end
