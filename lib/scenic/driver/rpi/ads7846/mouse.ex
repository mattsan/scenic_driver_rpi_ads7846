defmodule Scenic.Driver.Rpi.ADS7846.Mouse do
  @moduledoc false

  defstruct [:state, :touch, :x, :y, :size, :calibration, :rotate]

  def new(%{
        touch: touch,
        mouse_x: x,
        mouse_y: y,
        size: size,
        calibration: calibration,
        rotate: rotate
      }) do
    %__MODULE__{touch: touch, x: x, y: y, size: size, calibration: calibration, rotate: rotate}
  end

  def simulate(%__MODULE__{} = mouse_event, events) do
    Enum.reduce(events, mouse_event, fn
      {:ev_key, :btn_touch, 1}, %{touch: false} = mouse_event ->
        %{mouse_event | state: :down, touch: true}

      {:ev_key, :btn_touch, 0}, %{touch: true} = mouse_event ->
        %{mouse_event | state: :up, touch: false}

      {:ev_key, :btn_touch, 1}, %{touch: true} = mouse_event ->
        %{mouse_event | state: nil}

      {:ev_abs, :abs_x, x}, %{state: nil} = mouse_event ->
        %{mouse_event | state: :move, x: x}

      {:ev_abs, :abs_y, y}, %{state: nil} = mouse_event ->
        %{mouse_event | state: :move, y: y}

      {:ev_abs, :abs_x, x}, mouse_event ->
        %{mouse_event | x: x}

      {:ev_abs, :abs_y, y}, mouse_event ->
        %{mouse_event | y: y}

      _, mouse_event ->
        mouse_event
    end)
  end

  def get_input_event(%__MODULE__{} = mouse_event) do
    case mouse_event.state do
      :down ->
        {:cursor_button, {:left, :press, 0, get_screen_point(mouse_event)}}

      :up ->
        {:cursor_button, {:left, :release, 0, get_screen_point(mouse_event)}}

      :move ->
        {:cursor_pos, get_screen_point(mouse_event)}

      _ ->
        :no_input_event
    end
  end

  def update_state(%__MODULE__{} = mouse_event, state) when is_map(state) do
    case mouse_event.state do
      :up ->
        %{state | touch: mouse_event.touch, mouse_x: nil, mouse_y: nil}

      _ ->
        %{state | touch: mouse_event.touch, mouse_x: mouse_event.x, mouse_y: mouse_event.y}
    end
  end

  defp get_screen_point(mouse_event) do
    {mouse_event.x, mouse_event.y}
    |> calibrate(mouse_event)
    |> transform(mouse_event)
  end

  defp calibrate({x, y}, mouse_event) do
    precision = 3

    case mouse_event do
      %{calibration: {{ax, bx, dx}, {ay, by, dy}}} ->
        {
          Float.round(x * ax + y * bx + dx, precision),
          Float.round(y * ay + x * by + dy, precision)
        }

      _ ->
        {x, y}
    end
  end

  defp transform({x, y}, mouse_event) do
    case mouse_event do
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
