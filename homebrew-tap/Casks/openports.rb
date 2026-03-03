cask "openports" do
  version "1.1.9"
  
  on_arm do
    url "https://github.com/MohamedMohana/openports/releases/download/v1.1.9/OpenPorts-v1.1.9.zip",
        verified: "github.com/MohamedMohana/openports/"
    sha256 "26a2354a9ae7936424f05ec250f99810ff9730077dcc9b01a5ff64dd3c74cb4a"
  end
  
  on_intel do
    url "https://github.com/MohamedMohana/openports/releases/download/v1.1.9/OpenPorts-v1.1.9.zip",
        verified: "github.com/MohamedMohana/openports/"
    sha256 "26a2354a9ae7936424f05ec250f99810ff9730077dcc9b01a5ff64dd3c74cb4a"
  end
  
  name "OpenPorts"
  desc "Smart port monitoring for Mac developers with safety ratings and real-time updates"
  homepage "https://github.com/MohamedMohana/openports"
  
  auto_updates false
  depends_on macos: ">= :sonoma"
  
  app "OpenPorts.app"
  
  caveats do
    <<~CAVEAT
    On first launch, you may see a Gatekeeper security warning.
    
    To bypass:
      1. Open System Settings → Privacy & Security
      2. Find "OpenPorts was blocked from opening"
      3. Click "Open Anyway"
    
    This is normal for open-source apps without Apple Developer accounts.
    
    Release v2.0.1 packaging is being stabilized. If installation fails, use a manual download from Releases.
    CAVEAT
  end
end
