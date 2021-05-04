defmodule Scenic.Driver.Rpi.ADS7846 do
  use Scenic.ViewPort.Driver
  alias Scenic.Driver.Rpi.ADS7846.Mouse

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
    fingers: %{},
    mouse_x: nil,
    mouse_y: nil,
    mouse_event: nil,
    config: nil,
    calibration: nil,
    screen_size: nil
  }

  defguardp is_calibration(ax, bx, dx, ay, by, dy)
            when is_number(ax) and
                   is_number(bx) and
                   is_number(dx) and
                   is_number(ay) and
                   is_number(by) and
                   is_number(dy)

  @impl true
  def init(viewport, {_, _} = screen_size, config) do
    Process.send(self(), {:init_driver, @device}, [])

    state = %{
      @initial_state
      | viewport: viewport,
        config: config,
        calibration: get_calibration(config),
        screen_size: screen_size
    }

    {:ok, state}
  end

  @impl true
  def handle_call(_msg, _from, state) do
    {:reply, :e_no_impl, state}
  end

  @impl true
  def handle_cast(_msg, state) do
    {:noreply, state}
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
        Logger.warn("Device not found: #{inspect(requested_device)}")

        Process.send_after(self(), {:init_driver, requested_device}, @init_retry_ms)

        {:noreply, state}
    end
  end

  def handle_info({:input_event, event_path, events}, %{event_path: event_path} = state) do
    Logger.debug("input events: #{inspect(events, limit: :infinity)}")

    state =
      Enum.reduce(events, state, fn event, st ->
        event
        |> Mouse.ev_abs(st)
        |> Mouse.simulate_mouse(event)
      end)
      |> Mouse.send_mouse()

    Logger.debug("mouse event: #{inspect(state, limit: :infinity)}")

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info("Unhandled info. msg: #{inspect(msg)}")

    {:noreply, state}
  end

  @spec get_calibration(keyword()) ::
          {{number(), number(), number()}, {number(), number(), number()}} | nil
  defp get_calibration(config) do
    case config[:calibration] do
      {{ax, bx, dx}, {ay, by, dy}} = calibration when is_calibration(ax, bx, dx, ay, by, dy) ->
        Logger.debug("calibration: #{ax}, #{bx}, #{dx}, #{ay}, #{by}, #{dy}")
        calibration

      nil ->
        nil

      _ ->
        Logger.error("Invalid touch calibration in driver config")
        Logger.error("Must be a tuple in the form of {{ax, bx, dx}, {ay, by, dy}}")
        Logger.error("See documentation for details")

        nil
    end
  end

  defp find_device(devices, target_device) do
    devices
    |> Enum.find(fn {_event, %InputEvent.Info{name: name}} ->
      name =~ target_device
    end)
  end
end
