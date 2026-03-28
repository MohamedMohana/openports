cask "openports" do
  version "2.1.0"

  on_arm do
    url "https://github.com/MohamedMohana/openports/releases/download/v#{version}/OpenPorts-v#{version}-arm64.zip",
        verified: "github.com/MohamedMohana/openports/"
    sha256 "e2966109c90e4dc36929b3d1ec58a907fd628798d58213dceb55c4040bf456b5"
  end

  on_intel do
    url "https://github.com/MohamedMohana/openports/releases/download/v#{version}/OpenPorts-v#{version}-intel.zip",
        verified: "github.com/MohamedMohana/openports/"
    sha256 "59d2118f06861d77e90e020503160d232d076b79c54d5a148cb932f0c3959836"
  end

  name "OpenPorts"
  desc "Smart port monitoring for Mac developers"
  homepage "https://github.com/MohamedMohana/openports"

  auto_updates false
  depends_on macos: ">= :sonoma"

  app "OpenPorts.app"
end
