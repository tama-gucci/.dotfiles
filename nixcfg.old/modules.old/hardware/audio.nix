{ config, lib, pkgs, ... }:

with lib;

{
  # Use custom namespace to avoid conflict with NixOS's hardware options
  options.modules.audio.enable = mkEnableOption "Audio support (PipeWire)";

  config = mkIf config.modules.audio.enable {
    # Disable legacy PulseAudio (replaced by PipeWire)
    services.pulseaudio.enable = false;
    
    # PipeWire - modern audio/video server
    # Handles audio routing, Bluetooth audio, screen sharing
    services.pipewire = {
      enable = true;
      
      # Compatibility layers for different audio APIs
      alsa.enable = true;       # Low-level Linux audio (games, pro audio)
      alsa.support32Bit = true; # 32-bit game audio
      pulse.enable = true;      # PulseAudio apps (most desktop apps)
      jack.enable = true;       # Pro audio applications (Ardour, etc.)
      wireplumber.enable = true; # Session manager (handles device routing)
    };
    
    # Audio control utilities
    environment.systemPackages = with pkgs; [
      pavucontrol  # GUI volume/routing control
      pamixer      # CLI volume control
    ];
  };
}
