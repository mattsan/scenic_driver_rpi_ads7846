defmodule Scenic.Driver.Rpi.ADS7846.MixProject do
  use Mix.Project

  @rpi_targets [:rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :rpi4]

  def project do
    [
      app: :scenic_driver_rpi_ads7846,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      description: """
      Scenic Driver for ADS7846 with Raspberry Pi
      """
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
      {:input_event, "~> 0.4", targets: @rpi_targets},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  def docs do
    [
      extras: ["README.md"],
      main: "readme",
      groups_for_functions: [
        Guards: &(&1[:guard] == true)
      ]
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{github: "https://github.com/mattsan/scenic_driver_rpi_ads7846"}
    ]
  end
end
