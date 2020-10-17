defmodule Scenic.Driver.Rpi.ADS7846.MixProject do
  use Mix.Project

  def project do
    [
      app: :scenic_driver_rpi_ads7846,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:scenic, "~> 0.10"},
      {:input_event, "~> 0.4"}
    ]
  end
end
