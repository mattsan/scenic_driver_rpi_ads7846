defmodule Scenic.Driver.Rpi.ADS7846.Device do
  @moduledoc false

  require Logger

  case Mix.target() do
    target when target in [:rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :rpi4] ->
      def initialize(requested_device) do
        device_info =
          InputEvent.enumerate()
          |> Enum.find(fn {_, %InputEvent.Info{name: name}} ->
            name =~ requested_device
          end)

        case device_info do
          {event_path, %InputEvent.Info{}} ->
            {:ok, event_pid} = InputEvent.start_link(event_path)
            {:ok, {event_pid, event_path}}

          _ ->
            :not_found
        end
      end

    _ ->
      def initialize(_) do
        {:ok, {:event_pid, :event_path}}
      end
  end
end
