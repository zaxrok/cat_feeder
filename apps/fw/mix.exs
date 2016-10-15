defmodule CatFeeder.Mixfile do
  use Mix.Project

  @target System.get_env("NERVES_TARGET") || "rpi3"

  def project do
    [app: :cat_feeder,
     version: "0.0.1",
     target: @target,
     archives: [nerves_bootstrap: "~> 0.2"],
     deps_path: "deps/#{@target}",
     build_path: "_build/#{@target}",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps() ++ system(@target)]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [
      :logger,
      :elixir_ale,
      :gpio_rpi,
      :timex,
      :nerves,
      :nerves_system_br,
      :porcelain,
      :persistent_storage,
      :nerves_toolchain,
      :nerves_system,
      :nerves_toolchain_arm_unknown_linux_gnueabihf,
      :nerves_system_rpi3,
      :nerves_interim_wifi,
      ],
     mod: {CatFeeder, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:elixir_ale, "~> 0.4.1"},
      {:exrm, "~> 1.0.5"},
      {:timex, "~> 3.0"},
      {:nerves, "~> 0.3"},
      {:persistent_storage, git: "https://github.com/cellulose/persistent_storage.git", branch: "master"},
      {:gpio_rpi, git: "https://github.com/Hermanverschooten/gpio_rpi.git", branch: "master"},
      {:nerves_interim_wifi, git: "https://github.com/nerves-project/nerves_interim_wifi", branch: "master"}
    ]
  end

  def system(target) do
    [{:"nerves_system_#{target}", ">= 0.0.0"}]
  end

  def aliases do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end

end