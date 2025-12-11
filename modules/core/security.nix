{ ... }:

{
  # sudo - run commands as root (e.g., sudo nixos-rebuild switch)
  security.sudo.enable = true;
  
  # PolicyKit - handles graphical privilege escalation prompts
  # Required for apps that need root access (disk management, system settings)
  security.polkit.enable = true;
}
