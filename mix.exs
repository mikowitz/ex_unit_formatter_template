defmodule ExUnitFormatterTemplate.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_unit_formatter_template,
      name: "ExUnitFormatterTemplate",
      description: "Simple template for creating a custom formatter for use with ExUnit",
      version: "0.0.1",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["test/support" | elixirc_paths(:dev)]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.27", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.4", only: [:test]},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "ExUnitFormatterTemplate"
    ]
  end

  defp package do
    [
      name: :ex_unit_formatter_template,
      licenses: ["MIT"],
      links: %{
        "Github" => "https://github.com/mikowitz/ex_unit_formatter_template",
        "HexDocs" => "https://hexdocs.pm/ex_unit_formatter_template"
      }
    ]
  end
end
