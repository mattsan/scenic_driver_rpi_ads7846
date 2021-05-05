defmodule Scenic.Driver.Rpi.ADS7846 do
  use Scenic.ViewPort.Driver
  alias Scenic.Driver.Rpi.ADS7846.Mouse

  require Logger

  @type calibration :: {
          {number(), number(), number()},
          {number(), number(), number()}
        }

  @init_retry_ms 400
  @device "ADS7846 Touchscreen"
  @initial_state %{
    device: @device,
    event_path: nil,
    event_pid: nil,
    viewport: nil,
    slot: 0,
    touch: false,
    mouse_x: nil,
    mouse_y: nil,
    mouse_event: nil,
    config: nil,
    calibration: nil,
    size: nil
  }

  defguardp is_numbers(ax, bx, dx, ay, by, dy)
            when is_number(ax) and
                   is_number(bx) and
                   is_number(dx) and
                   is_number(ay) and
                   is_number(by) and
                   is_number(dy)

  @impl true
  def init(viewport, {_, _} = size, config) do
    init_driver(@device)

    state = %{
      @initial_state
      | viewport: viewport,
        config: config,
        calibration: get_calibration(config),
        size: size
    }

    {:ok, state}
  end

  @impl true
  def handle_info({:init_driver, requested_device}, state) do
    InputEvent.enumerate()
    |> find_device(requested_device)
    |> case do
      {event, %InputEvent.Info{}} ->
        {:ok, pid} = InputEvent.start_link(event)

        Logger.info("ADS7846 Driver initialized")

        {:noreply, %{state | event_pid: pid, event_path: event}}

      nil ->
        Logger.warning("Device not found: #{inspect(requested_device)}")

        init_driver_after(requested_device, @init_retry_ms)

        {:noreply, state}
    end
  end

  def handle_info({:input_event, event_path, events}, %{event_path: event_path} = state) do
    Logger.debug("input events: #{inspect(events, limit: :infinity)}")

    state =
      Enum.reduce(events, state, fn event, st ->
        st
        |> Mouse.ev_abs(event)
        |> Mouse.simulate_mouse(event)
      end)
      |> Mouse.send_mouse()

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info("Unhandled message. msg: #{inspect(msg, limit: :infinity)}")

    {:noreply, state}
  end

  defp init_driver(device) do
    Process.send(self(), {:init_driver, device}, [])
  end

  defp init_driver_after(device, msec) do
    Process.send_after(self(), {:init_driver, device}, msec)
  end

  @spec get_calibration(keyword()) :: calibration() | nil
  defp get_calibration(config) do
    case config[:calibration] do
      {{ax, bx, dx}, {ay, by, dy}} = calibration when is_numbers(ax, bx, dx, ay, by, dy) ->
        Logger.debug(
          "calibration ax: #{ax}, bx: #{bx}, dx: #{dx}, ay: #{ay}, by: #{by}, dy: #{dy}"
        )

        calibration

      nil ->
        Logger.warning("Touch calibration is not defined in driver config")
        nil

      _ ->
        Logger.error("Invalid touch calibration in driver config")
        nil
    end
  end

  defp find_device(devices, requested_device) do
    devices
    |> Enum.find(fn {_event, %InputEvent.Info{name: name}} -> name =~ requested_device end)
  end
end
