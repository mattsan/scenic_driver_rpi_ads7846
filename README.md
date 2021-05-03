# Scenic.Driver.Rpi.ADS7846

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `scenic_driver_rpi_ads7846` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:scenic_driver_rpi_ads7846, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/scenic_driver_rpi_ads7846](https://hexdocs.pm/scenic_driver_rpi_ads7846).

## Configuration

```elixir
use Mix.Config

config :my_app, :viewport, %{
  name: :main_viewport,
  default_scene: {MyApp.Scene.SysInfo, nil},
  size: {800, 480},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Nerves.Rpi
    },
    %{
      module: Scenic.Driver.Rpi.ADS7846,
      opts: [
        device: "ADS7846 Touchscreen",
        calibration: {
          {0.086, 0, -17.297},
          {0.130, 0, -25.946}
        }
      ]
    }
  ]
}
```
