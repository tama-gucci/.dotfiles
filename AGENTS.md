# Personal NixOS configuration

Use the pinned Chrysalis system rules and the existing flake-parts/import-tree feature layout.
Keep the flake entrypoint thin, select named features per host and keep related NixOS/Home Manager
settings together. Import discovery defines features; host selection enables them.

The Chrysalis module is the single source for Pi, Cage, Ghostty, tmux and the pinned operations
backend. Do not duplicate those integrations here. Read the installed chrysalis-system skill
when changing this system. Build and diff the exact locked host before activation. Preserve
installed system and Home Manager stateVersion, passwords, hardware identities and Secure Boot
keys. Physical Surface/NVIDIA behavior and hibernation offsets need actual machine verification.

Use native /chrysalis system for OS outcomes and its generated ledger. Existing personal-vault
records retain exact review and approval. Keep facts, credentials, state, test images and private
vaults outside this reusable repository. Never put password literals or encryption keys in Nix.
