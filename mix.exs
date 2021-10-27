defmodule Meow.MixProject do
  use Mix.Project

  @version "0.1.0-dev"
  @description "Multipopulation evolutionary algorithms in Elixir"

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
      {:vega_lite, "~> 0.1.1", optional: true},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: "https://github.com/jonatanklosko/meow",
      # source_ref: "v#{@version}"
      source_ref: "main",
      extras: [
        {:"README.md", [title: "Readme"]},
        {:"notebooks/rastrigin_intro.livemd", [title: "Introduction"]},
        {:"notebooks/metrics.livemd", [title: "Metrics and visualizations"]}
      ],
      groups_for_modules: [
        Model: [
          Meow.Model,
          Meow.Pipeline,
          Meow.Topology,
          Meow.Ops,
          MeowNx.Ops
        ],
        Runtime: [
          Meow.Runner,
          Meow.Runner.Report,
          Meow.Distribution
        ],
        "Numerical definitions": [
          MeowNx.Init,
          MeowNx.Selection,
          MeowNx.Crossover,
          MeowNx.Mutation,
          MeowNx.Metric
        ],
        "Lower level": [
          Meow.Op,
          Meow.Op.Context,
          Meow.Population,
          Meow.RepresentationSpec,
          MeowNx.RepresentationSpec
        ]
      ],
      groups_for_functions: [
        # Meow.Ops
        "Operations: Termination": &(&1[:type] == :termination),
        "Operations: Flow": &(&1[:type] == :flow),
        "Operations: Multi-population": &(&1[:type] == :multi),

        # MeowNx.Ops
        "Operations: Initialization": &(&1[:type] == :init),
        "Operations: Selection": &(&1[:type] == :selection),
        "Operations: Crossover": &(&1[:type] == :crossover),
        "Operations: Mutation": &(&1[:type] == :mutation),
        "Operations: Logging": &(&1[:type] == :log)
      ],
      before_closing_body_tag: &before_closing_body_tag/1
    ]
  end

  # Add KaTeX integration for rendering math
  defp before_closing_body_tag(:html) do
    """
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.13.0/dist/katex.min.css" integrity="sha384-t5CR+zwDAROtph0PXGte6ia8heboACF9R5l/DiY+WZ3P2lxNgvJkQk5n7GPvLMYw" crossorigin="anonymous">
    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.13.0/dist/katex.min.js" integrity="sha384-FaFLTlohFghEIZkw6VGwmf9ISTubWAVYW8tG8+w2LAIftJEULZABrF9PPFv+tVkH" crossorigin="anonymous"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/katex@0.13.0/dist/contrib/auto-render.min.js" integrity="sha384-bHBqxz8fokvgoJ/sc17HODNxa42TlaEhB+w8ZJXTc2nZf1VgEaFZeZvT4Mznfz0v" crossorigin="anonymous"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function() {
        renderMathInElement(document.body, {
          delimiters: [
            { left: "$$", right: "$$", display: true },
            { left: "$", right: "$", display: false },
          ]
        });
      });
    </script>
    """
  end

  defp before_closing_body_tag(_), do: ""
end
