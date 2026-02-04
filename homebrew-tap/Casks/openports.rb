cask "openports" do
  version "1.0.6"
  sha256 "3912e454e19ad1cb63568ac289d0bcf3db0c07bbc1f95de53c00805c8b780da6"

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
