cask "openports" do
  version "1.0.3"
  sha256 "cac0f148bbdf11be29b63b584c5b77f00b30ec997beed80df7753c8ad2eea3b6"

  url "https://github.com/MohamedMohana/openports/releases/download/v#{version}/OpenPorts-#{version}.zip",
      verified: "github.com/MohamedMohana/openports/"
  name "OpenPorts"
  desc "Lightweight macOS menu bar app for monitoring local ports and processes"
  homepage "https://github.com/MohamedMohana/openports"

  auto_updates false
  depends_on arch: :arm64
  depends_on macos: ">= :sonoma"

  app "OpenPorts.app"
end
