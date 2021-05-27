defmodule Meow.MixProject do
  use Mix.Project

  @version "0.1.0-dev"
  @description "Elixir bindings to Vega-Lite"

  def project do
    [
      app: :meow,
      version: @version,
      description: @description,
      name: "Meow",
      elixir: "~> 1.12",
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", branch: "main", sparse: "nx"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/jonatanklosko/meow",
      # source_ref: "v#{@version}"
      source_ref: "main"
    ]
  end
end
