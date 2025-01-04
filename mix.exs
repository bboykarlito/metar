defmodule Metar.MixProject do
  use Mix.Project

  def project do
    [
      app: :metar,
      version: "0.1.0",
      description: "Library for decoding raw METAR reports.",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      name: "Metar",
      source_url: "https://github.com/bboykarlito/metar"
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/bboykarlito/metar"}
    ]
  end
end
