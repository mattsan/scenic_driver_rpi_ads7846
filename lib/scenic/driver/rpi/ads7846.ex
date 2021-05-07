defmodule Scenic.Driver.Rpi.ADS7846 do
  use Scenic.ViewPort.Driver

  alias Scenic.Driver.Rpi.ADS7846.{Config, Event}
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
    config: nil,
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
        config: config,
        calibration: Config.get_calibration(config),
        rotate: Config.get_rotate(config),
        size: size
    }

    {:ok, state}
  end

  @impl true
  def handle_info(_, _)

  def handle_info({:init_driver, requested_device}, state) do
    device_info = find_device(requested_device)

    {:noreply, init_driver(state, device_info)}
  end

  def handle_info({:input_event, event_path, events}, %{event_path: event_path} = state) do
    Logger.debug("input events: #{inspect(events, limit: :infinity)}")

    state =
      state
      |> Event.simulate(events)
      |> Event.send_event(&ViewPort.input(state.viewport, &1))

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info("Unhandled message. msg: #{inspect(msg, limit: :infinity)}")

    {:noreply, state}
  end

  defp find_device(requested_device) do
    device_info =
      InputEvent.enumerate()
      |> Enum.find(fn {_, %InputEvent.Info{name: name}} ->
        name =~ requested_device
      end)

    case device_info do
      {_event, %InputEvent.Info{}} ->
        device_info

      _ ->
        {:not_found, requested_device}
    end
  end

  defp init_driver(state, {event, %InputEvent.Info{}}) do
    {:ok, pid} = InputEvent.start_link(event)

    Logger.info("ADS7846 Driver initialized")

    %{state | event_pid: pid, event_path: event}
  end

  defp init_driver(state, {:not_found, requested_device}) do
    Logger.warning("#{requested_device} not found. Retry to find it.")

    Process.send_after(self(), {:init_driver, requested_device}, @init_retry_ms)

    state
  end
end
