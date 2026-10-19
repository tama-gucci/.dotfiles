# Personal NixOS configuration

The flake uses flake-parts/import-tree and named feature modules. Both existing hosts select the
shared Chrysalis integration: Cage opens Ghostty, tmux and ordinary Pi. Chrysalis supplies the
module, Pi package, short system rules and pinned operations backend; this repository supplies
personal preferences and actual host hardware.

- flake.nix declares inputs; flake.lock pins them.
- modules/meta.nix holds owner preferences.
- modules/configurations.nix assembles hosts.
- modules/nixos/chrysalis.nix consumes the reusable integration.
- modules/hosts selects features and preserves each machine's identities.
- modules/interface and modules/applications retain optional fuller desktop features.

Use /chrysalis system in the normal Pi terminal for an OS outcome. The native scope binds this
editable configuration and host; verified receipt events project into the selected Obsidian vault.
Personal records retain their exact native approvals. Ordinary sudo still requires authentication;
upstream nix-agent delegates only its configured administrative commands. No default password is
committed. Existing account passwords and system/Home Manager stateVersion 25.11 are preserved.

To restore a fuller desktop, select its interface features in the host and set
programs.chrysalis-pi.terminal.enable = false so Cage does not compete for the login terminal.
The Pi integration remains available through the ordinary terminal. Feature discovery alone
does not enable every desktop or application.

Run nix flake check --no-build, then build the exact host before activation. Surface/NVIDIA,
hibernation offsets and firmware keys are existing machine-specific choices; these changes do
not establish physical hardware acceptance or enroll Secure Boot keys. Use the Chrysalis
installer's measured facts for new machines rather than copying these hardware identities.

The Chrysalis input pins published revision 79961a0855cfb0407ff6cb7a84fdcbf3630e5b90.
Update flake.nix to another reviewed published revision, then run nix flake lock --update-input
chrysalis and evaluate both hosts before activation. Keep the input and lockfile changes together;
never publish a local development path in flake.lock.

This consumes the NixOS prototype. Package and configuration checks do not establish the
outstanding x86 installer/VM or physical hardware acceptance.
