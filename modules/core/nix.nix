{ ... }:

{
  nix.settings = {
    # Enable modern Nix CLI commands (nix build, nix develop, etc.) and flakes
    experimental-features = [ "nix-command" "flakes" ];
    
    # Parallel build jobs (set to number of CPU cores)
    max-jobs = "auto";
    
    # Deduplicate identical files in /nix/store to save disk space
    auto-optimise-store = true;
    
    # Don't warn about uncommitted git changes when building
    warn-dirty = false;
  };
  
  # Automatic garbage collection - removes old unused packages weekly
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";  # Keep last 30 days of generations
  };
  
  # Allow installing proprietary software (NVIDIA drivers, Steam, etc.)
  nixpkgs.config.allowUnfree = true;
}
