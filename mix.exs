defmodule KinoUserPresence.MixProject do
  use Mix.Project

  def project do
    [
      app: :kino_user_presence,
      version: "0.1.1",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      description: description(),
      name: "Kino User Presence",
      deps: deps(),
      package: package()
    ]
  end

  def description() do
    """
    Provides user presence tracking functionality for Livebook applications.
    """
  end

  def package() do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/elepedus/kino_user_presence"}
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
      {:kino, "~> 0.13.2"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
