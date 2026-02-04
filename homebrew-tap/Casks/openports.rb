cask "openports" do
  version "1.0.5"
  sha256 "8fac53b6d424c65e98af299ee2934373dd05368988ee6fd513166e342d401892"

  url "https://github.com/MohamedMohana/openports/releases/download/v#{version}/OpenPorts-v#{version}.zip",
      verified: "github.com/MohamedMohana/openports/"
  name "OpenPorts"
  desc "Lightweight macOS menu bar app for monitoring local ports and processes"
  homepage "https://github.com/MohamedMohana/openports"

  auto_updates false
  depends_on arch: :arm64
  depends_on macos: ">= :sonoma"

  app "OpenPorts.app"
end
