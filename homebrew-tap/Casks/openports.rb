cask "openports" do
  version "1.1.6"
  sha256 :no_check

  url "https://github.com/MohamedMohana/openports/releases/download/v1.1.6/OpenPorts-v1.1.6.zip",
      verified: "github.com/MohamedMohana/openports/"
  name "OpenPorts"
  desc "Lightweight macOS menu bar app for monitoring local ports and processes with safety ratings and fixed Preferences UI"
  homepage "https://github.com/MohamedMohana/openports"

  auto_updates false
  depends_on arch: :arm64
  depends_on macos: ">= :sonoma"

  app "OpenPorts.app"
end
