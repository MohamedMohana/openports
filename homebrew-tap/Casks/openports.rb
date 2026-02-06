cask "openports" do
  version "1.1.7"
  sha256 :no_check

  url "https://github.com/MohamedMohana/openports/releases/download/v1.1.7/OpenPorts-v1.1.7.zip",
      verified: "github.com/MohamedMohana/openports/"
  name "OpenPorts"
  desc "Lightweight macOS menu bar app for monitoring local ports and processes with safety ratings and working Preferences that sync with app"
  homepage "https://github.com/MohamedMohana/openports"

  auto_updates false
  depends_on arch: :arm64
  depends_on macos: ">= :sonoma"

  app "OpenPorts.app"
end
