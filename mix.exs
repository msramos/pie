defmodule Pie.MixProject do
  use Mix.Project

  def project do
    [
      app: :pie,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Pie",
      source_url: "https://github.com/msramos/pie"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.22.6", only: :dev, runtime: :false}
    ]
  end
end
