defmodule Scenic.Driver.Rpi.ADS7846 do
  use Scenic.ViewPort.Driver
  alias Scenic.ViewPort

  require Logger

  defguardp is_pos(x, y) when is_number(x) and is_number(y)

  @init_retry_ms 400
  @device "ADS7846 Touchscreen"

  @impl true
  def init(viewport, {_, _} = screen_size, config) do
    Process.send(self(), {:init_driver, @device}, [])

    calibration =
      case config[:calibration] do
        nil ->
          nil

        {{ax, bx, dx}, {ay, by, dy}} = calib
        when is_number(ax) and
               is_number(bx) and
               is_number(dx) and
               is_number(ay) and
               is_number(by) and
               is_number(dy) ->
          calib

        _ ->
          msg =
            "Invalid touch calibration in driver config\r\n" <>
              "Must be a tuple in the form of {{ax, bx, dx}, {ay, by, dy}}\r\n" <>
              "See documentation for details"

          Logger.error(msg)
          nil
      end

    state = %{
      device: @device,
      event_path: nil,
      event_pid: nil,
      viewport: viewport,
      slot: 0,
      touch: false,
      fingers: %{},
      mouse_x: nil,
      mouse_y: nil,
      mouse_event: nil,
      config: config,
      calibration: calibration,
      screen_size: screen_size
    }

    {:ok, state}
  end

  @impl true
  def handle_call(_msg, _from, state), do: {:reply, :e_no_impl, state}

  @impl true
  def handle_cast(_msg, state), do: {:noreply, state}

  @impl true
  def handle_info({:init_driver, requested_device}, state) do
    InputEvent.enumerate()
    |> Enum.find_value(fn
      # input_event 0.3.1
      {event, device_name} when is_binary(device_name) ->
        if device_name =~ requested_device do
          event
        else
          nil
        end

      # input_event >= 0.4.0
      {event, info} when is_map(info) ->
        if info.name =~ requested_device do
          event
        else
          nil
        end
    end)
    |> case do
      nil ->
        Logger.warn("Device not found: #{inspect(requested_device)}")
        Process.send_after(self(), {:init_driver, requested_device}, @init_retry_ms)
        {:noreply, state}

      event ->
        {:ok, pid} = InputEvent.start_link(event)

        {:noreply, %{state | event_pid: pid, event_path: event}}
    end
  end

  def handle_info({:input_event, event_path, events}, %{event_path: event_path} = state) do
    state =
      Enum.reduce(events, state, fn event, st ->
        event
        |> ev_abs(st)
        |> simulate_mouse(event)
      end)
      |> send_mouse()

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info("Unhandled info. msg: #{inspect(msg)}")
    {:noreply, state}
  end

  defp ev_abs(event, state) do
    case {event, state} do
      {{:ev_key, :btn_touch, 1}, %{touch: touch}} ->
        mouse_event = if touch, do: nil, else: :mouse_down
        %{state | touch: true, mouse_event: mouse_event}

      {{:ev_key, :btn_touch, 0}, %{touch: touch}} ->
        mouse_event = if touch, do: :mouse_up, else: nil
        %{state | touch: false, mouse_event: mouse_event}

      {_, state} ->
        state
    end
  end

  defp simulate_mouse(state, event) do
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

  defp send_mouse(state)

  defp send_mouse(%{viewport: viewport, mouse_x: x, mouse_y: y, mouse_event: :mouse_down} = state)
       when is_pos(x, y) do
    pos = project_pos({x, y}, state)

    Logger.debug(
      "ViewPort.input(#{inspect(viewport)}, {:cursor_button, {:left, :press, 0, #{inspect(pos)}}})"
    )

    ViewPort.input(viewport, {:cursor_button, {:left, :press, 0, pos}})
    %{state | mouse_event: nil}
  end

  defp send_mouse(%{viewport: viewport, mouse_x: x, mouse_y: y, mouse_event: :mouse_up} = state)
       when is_pos(x, y) do
    pos = project_pos({x, y}, state)

    Logger.debug(
      "ViewPort.input(#{inspect(viewport)}, {:cursor_button, {:left, :release, 0, #{inspect(pos)}}})"
    )

    ViewPort.input(viewport, {:cursor_button, {:left, :release, 0, pos}})
    %{state | mouse_x: nil, mouse_y: nil, mouse_event: nil}
  end

  defp send_mouse(%{viewport: viewport, mouse_x: x, mouse_y: y, mouse_event: :mouse_move} = state)
       when is_pos(x, y) do
    pos = project_pos({x, y}, state)
    Logger.debug("ViewPort.input(#{inspect(viewport)}, {:cursor_pos, #{inspect(pos)}})")
    ViewPort.input(viewport, {:cursor_pos, pos})
    %{state | mouse_event: nil}
  end

  defp send_mouse(%{mouse_event: :mouse_up} = state) do
    %{state | mouse_x: nil, mouse_y: nil, mouse_event: nil}
  end

  defp send_mouse(state) do
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
