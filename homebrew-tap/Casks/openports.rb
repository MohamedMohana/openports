cask "openports" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/MohamedMohana/openports/releases/download/v#{version}/OpenPorts-#{version}.zip"
  name "OpenPorts"
  desc "Lightweight macOS menu bar app for monitoring local ports and processes"
  homepage "https://github.com/MohamedMohana/openports"

  auto_updates false
  depends_on arch: :arm64
  depends_on macos: ">= :sonoma"

  app "OpenPorts.app"
end
