defmodule Scenic.Driver.Rpi.ADS7846 do
  use Scenic.ViewPort.Driver

  alias Scenic.Driver.Rpi.ADS7846.{Config, Device, Mouse}
  alias Scenic.ViewPort

  require Logger

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
    calibration: nil,
    rotate: 0,
    size: nil
  }

  @impl true
  def init(viewport, {_, _} = size, config) do
    Process.send(self(), {:init_driver, @device}, [])

    state = %{
      @initial_state
      | viewport: viewport,
        calibration: Config.get_calibration(config),
        rotate: Config.get_rotate(config),
        size: size
    }

    {:ok, state}
  end

  @impl true
  def handle_info(message, state)

  def handle_info({:init_driver, requested_device}, state) do
    Logger.info("Initializing #{requested_device} Driver")

    case Device.initialize(requested_device) do
      {:ok, {event_pid, event_path}} ->
        Logger.info("#{requested_device} Driver initialized")

        {:noreply, %{state | event_pid: event_pid, event_path: event_path}}

      :not_found ->
        Logger.warning("#{requested_device} not found. Retry to find it.")

        Process.send_after(self(), {:init_driver, requested_device}, @init_retry_ms)

        {:noreply, state}
    end
  end

  def handle_info({:input_event, event_path, events}, %{event_path: event_path} = state) do
    Logger.debug("input events: #{inspect(events, limit: :infinity)}")

    {new_state, input_event} =
      state
      |> Mouse.simulate(events)
      |> Mouse.get_input_event()

    if is_tuple(input_event) do
      Logger.debug("input_event: #{inspect(input_event, limit: :infinity)}")
      ViewPort.input(state.viewport, input_event)
    end

    {:noreply, new_state}
  end

  def handle_info(message, state) do
    Logger.info("Unhandled message: #{inspect(message, limit: :infinity)}")

    {:noreply, state}
  end
end
