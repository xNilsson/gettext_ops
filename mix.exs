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
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        flags: [:error_handling, :underspecs]
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/xnilsson/gettext_ops"},
      maintainers: ["Christopher Nilsson"],
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "GettextOps",
      extras: ["README.md", "CHANGELOG.md", "LICENSE"],
      source_url: "https://github.com/xnilsson/gettext_ops",
      source_ref: "v0.1.0",
      groups_for_modules: [
        Core: [
          GettextOps,
          GettextOps.Config,
          GettextOps.Parser,
          GettextOps.Entry,
          GettextOps.Writer,
          GettextOps.Output
        ],
        Operations: [
          GettextOps.Operations.ListUntranslated,
          GettextOps.Operations.Search,
          GettextOps.Operations.SearchValue,
          GettextOps.Operations.Translate,
          GettextOps.Operations.ChangeMsgid
        ],
        "Mix Tasks": [
          Mix.Tasks.GettextOps.ListUntranslated,
          Mix.Tasks.GettextOps.Search,
          Mix.Tasks.GettextOps.SearchValue,
          Mix.Tasks.GettextOps.Translate,
          Mix.Tasks.GettextOps.ChangeMsgid
        ]
      ]
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
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end
end
