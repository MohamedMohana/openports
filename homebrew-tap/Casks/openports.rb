cask "openports" do
  version "1.0.0"
  sha256 "99b4fb3534369e3bbf5c9712196cc2bb06edc554fcf2952e97afd6a8de78811f"

  url "https://github.com/MohamedMohana/openports/releases/download/v1.0.0/OpenPorts-#{version}-fixed.zip",
      verified: "github.com/MohamedMohana/openports/"
  name "OpenPorts"
  desc "Lightweight macOS menu bar app for monitoring local ports and processes"
  homepage "https://github.com/MohamedMohana/openports"

  auto_updates false
  depends_on arch: :arm64
  depends_on macos: ">= :sonoma"

  app "OpenPorts.app"
end
