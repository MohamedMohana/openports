cask "openports" do
  version "1.0.1"
  sha256 "f9d9a2a97032930c66f5671f3bae8011052e2d292c3ef9412f27bd9d6d148520"

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
