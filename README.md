# NixOS Configuration - Dendritic Pattern

This configuration uses the **dendritic pattern** from [mightyiam/dendritic](https://github.com/mightyiam/dendritic) for modular, composable, and DRY NixOS system configurations.

## Structure

```
.dotfiles/
├── flake.nix              # Entry point (rename flake.nix.new to use)
└── modules.new/           # Flake-parts modules (rename to modules/ to use)
    ├── flake-parts.nix    # Enables flake.modules option
    ├── meta.nix           # Owner info & defaults
    ├── configurations.nix # Builds nixosConfigurations
    ├── nixpkgs.nix        # Nixpkgs config & overlays
    ├── nix.nix            # Nix settings
    │
    ├── nixos/             # NixOS module hierarchy
    │   ├── base.nix       # Foundation (ALL systems)
    │   ├── pc.nix         # Personal computer (inherits base)
    │   ├── desktop.nix    # Desktop-specific (inherits pc)
    │   └── laptop.nix     # Laptop-specific (inherits pc)
    │
    ├── hardware/          # Hardware modules
    │   ├── nvidia.nix     # NVIDIA GPU with Optimus support
    │   ├── secureboot.nix # Lanzaboote secure boot
    │   ├── monitors.nix   # Monitor configuration library
    │   └── hibernation.nix# Swapfile hibernation
    │
    ├── interface/         # Window managers & shells
    │   ├── hyprland.nix   # Hyprland compositor
    │   ├── niri.nix       # Niri scrolling WM
    │   └── noctalia.nix   # Noctalia shell
    │
    ├── applications/      # Application modules
    │   ├── gaming.nix     # Steam, Lutris, etc.
    │   ├── development.nix# Dev tools & languages
    │   └── zen-browser.nix# Zen Browser
    │
    └── hosts/             # Host configurations
        ├── obelisk.nix    # Desktop PC
        └── diatom.nix     # Laptop
```

## Key Concepts

### Module Inheritance

```
base → pc → desktop (obelisk)
        └→ laptop  (diatom)
```

Each level adds to the previous:
- **base**: boot, security, networking, nix settings
- **pc**: user account, audio, bluetooth, home-manager
- **desktop**: performance governor, no power saving
- **laptop**: power management, lid switch, battery

### Named Modules

Modules are accessed via `config.flake.modules.nixos.*`:

```nix
configurations.nixos.myhost = {
  system = "x86_64-linux";
  modules = with config.flake.modules.nixos; [
    desktop
    nvidia
    hyprland
    gaming
  ];
};
```

### Centralized Metadata

[meta.nix](modules.new/meta.nix) contains shared configuration:

```nix
config.flake.meta = {
  owner = {
    username = "sin";
    name = "Sin";
    email = "...";
  };
  defaults = {
    shell = "fish";
    editor = "nvim";
    terminal = "kitty";
    # ...
  };
};
```

## Hosts

### Obelisk (Desktop)
- Intel CPU, NVIDIA GPU
- Hyprland + Noctalia
- Gaming, Development
- LUKS-encrypted BTRFS

### Diatom (Laptop)
- Intel CPU, NVIDIA Optimus
- Power management, hibernation
- Same software stack as desktop

## Usage

```bash
# Rename files to activate new structure
mv flake.nix flake.nix.old
mv flake.nix.new flake.nix
mv modules modules.old
mv modules.new modules

# Build configuration
sudo nixos-rebuild switch --flake .#obelisk  # Desktop
sudo nixos-rebuild switch --flake .#diatom   # Laptop

# Update flake
nix flake update
```

## Adding a New Host

1. Create `modules/hosts/myhost.nix`:

```nix
{ config, ... }:
let
  modules = config.flake.modules.nixos;
in
{
  configurations.nixos.myhost = {
    system = "x86_64-linux";
    modules = [
      modules.desktop  # or modules.laptop
      modules.nvidia   # if needed
      # ... other modules
      
      # Hardware-specific config
      ({ ... }: {
        networking.hostName = "myhost";
        # ... filesystem configuration
      })
    ];
  };
}
```

2. Rebuild: `sudo nixos-rebuild switch --flake .#myhost`

## Credits

- [mightyiam/dendritic](https://github.com/mightyiam/dendritic) - Dendritic pattern
- [flake-parts](https://flake.parts) - Flake infrastructure
- [import-tree](https://github.com/vic/import-tree) - Auto-importing
