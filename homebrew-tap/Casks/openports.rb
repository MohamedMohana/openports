cask "openports" do
  version "1.1.9"
  
  on_arm do
    url "https://github.com/MohamedMohana/openports/releases/download/v1.1.9/OpenPorts-v1.1.9.zip",
        verified: "github.com/MohamedMohana/openports/"
    sha256 "PENDING_COMPUTATION"
  end
  
  on_intel do
    # Intel support coming in v2.0.0
    # For now, show helpful message
    url "https://github.com/MohamedMohana/openports/releases/download/v1.1.9/OpenPorts-v1.1.9.zip",
        verified: "github.com/MohamedMohana/openports/"
    sha256 "PENDING_COMPUTATION"
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
    
    Intel Mac users: Native Intel support coming in v2.0.0!
    CAVEAT
  end
end
