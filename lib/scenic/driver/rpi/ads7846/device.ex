defmodule Scenic.Driver.Rpi.ADS7846.Device do
  @moduledoc false

  require Logger

  def initialize(state, requested_device) do
    device_info = find_device(requested_device)
    init_driver(state, device_info)
  end

  case Mix.target() do
    target when target in [:rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :rpi4] ->
      @init_retry_ms 400

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

      defp init_driver(state, device_info) do
        case device_info do
          {event_path, %InputEvent.Info{}} ->
            {:ok, event_pid} = InputEvent.start_link(event_path)

            Logger.info("ADS7846 Driver initialized")

            %{state | event_pid: event_pid, event_path: event_path}

          {:not_found, requested_device} ->
            Logger.warning("#{requested_device} not found. Retry to find it.")

            Process.send_after(self(), {:init_driver, requested_device}, @init_retry_ms)

            state
        end
      end

    _ ->
      defp find_device(_) do
        :ok
      end

      defp init_driver(state, :ok) do
        state
      end
  end
end
