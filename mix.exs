defmodule GettextOps.MixProject do
  use Mix.Project

  def project do
    [
      app: :gettext_ops,
      version: "0.1.0",
      elixir: "~> 1.18",
      description: "Targeted Mix tasks for Phoenix Gettext translations",
      package: package(),
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/xnilsson/gettext_ops"},
      maintainers: ["Christopher Nilsson"]
    ]
  end

  defp docs do
    [
      main: "GettextOps",
      extras: ["README.md"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:expo, "~> 1.1"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end
end
