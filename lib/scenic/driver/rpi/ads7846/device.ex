defmodule Scenic.Driver.Rpi.ADS7846.Device do
  @moduledoc false

  @spec initialize(String.t()) :: {:ok, {any(), any()}} | :not_found
  def initialize(requested_device)

  case Mix.target() do
    target when target in [:rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :rpi4] ->
      def initialize(requested_device) do
        InputEvent.enumerate()
        |> Enum.find(fn {_, %InputEvent.Info{name: name}} -> name =~ requested_device end)
        |> case do
          {event_path, %InputEvent.Info{}} ->
            {:ok, event_pid} = InputEvent.start_link(event_path)
            {:ok, {event_pid, event_path}}

          _ ->
            :not_found
        end
      end

    _ ->
      # Mock function for other targets.
      def initialize(requested_device) do
        if !is_nil(requested_device) do
          {:ok, {:event_pid, :event_path}}
        else
          :not_found
        end
      end
  end
end
