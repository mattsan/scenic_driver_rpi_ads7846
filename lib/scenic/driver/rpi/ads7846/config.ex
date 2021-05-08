defmodule Scenic.Driver.Rpi.ADS7846.Config do
  @moduledoc false

  require Logger

  @type calibration :: {
          {number(), number(), number()},
          {number(), number(), number()}
        }

  defguardp is_numbers(ax, bx, dx, ay, by, dy)
            when is_number(ax) and is_number(bx) and is_number(dx) and
                   is_number(ay) and is_number(by) and is_number(dy)

  @spec get_calibration(keyword()) :: calibration() | nil
  def get_calibration(config) do
    case config[:calibration] do
      {{ax, bx, dx}, {ay, by, dy}} = calibration when is_numbers(ax, bx, dx, ay, by, dy) ->
        Logger.debug("coifig calibration: #{inspect(calibration)}")
        calibration

      nil ->
        Logger.warning("Touch calibration is not defined in driver config")
        nil

      _ ->
        Logger.error("Invalid touch calibration in driver config")
        nil
    end
  end

  @spec get_rotate(keyword()) :: 0 | 1 | 2 | 3
  def get_rotate(config) do
    case config[:rotate] do
      rotate when rotate in [0, 1, 2, 3] -> rotate
      _ -> 0
    end
  end
end
