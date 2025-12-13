{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.git;
in
{
  options.modules.git = {
    enable = mkEnableOption "Git version control" // { default = true; };
    
    userName = mkOption {
      type = types.str;
      default = "";
      description = "Git user name for commits";
    };
    
    userEmail = mkOption {
      type = types.str;
      default = "";
      description = "Git user email for commits";
    };
    
    defaultBranch = mkOption {
      type = types.str;
      default = "main";
      description = "Default branch name for new repositories";
    };
    
    editor = mkOption {
      type = types.str;
      default = "nvim";
      description = "Default editor for commit messages";
    };
    
    signing = {
      enable = mkEnableOption "GPG commit signing";
      key = mkOption {
        type = types.str;
        default = "";
        description = "GPG key ID for signing commits";
      };
    };
  };

  config = mkIf cfg.enable {
    # System-level git
    programs.git = {
      enable = true;
      lfs.enable = true;
    };
    
    # User-level git configuration via Home Manager
    home-manager.users.${config.modules.user.name} = {
      programs.git = {
        enable = true;
        
        settings = {
          user = {
            name = mkIf (cfg.userName != "") cfg.userName;
            email = mkIf (cfg.userEmail != "") cfg.userEmail;
          };
          init.defaultBranch = cfg.defaultBranch;
          core.editor = cfg.editor;
          pull.rebase = true;
          push.autoSetupRemote = true;
          fetch.prune = true;
          
          # Better diffs
          diff.colorMoved = "default";
          
          # Reuse recorded resolution (remembers merge conflict fixes)
          rerere.enabled = true;

          aliases = {
            st = "status -sb";
            co = "checkout";
            br = "branch";
            ci = "commit";
            cm = "commit -m";
            ca = "commit --amend";
            unstage = "reset HEAD --";
            last = "log -1 HEAD";
            lg = "log --oneline --graph --decorate -10";
            lga = "log --oneline --graph --decorate --all";
            undo = "reset --soft HEAD~1";
            stash-all = "stash save --include-untracked";
          };
        };  
        
        # GPG signing
        signing = mkIf cfg.signing.enable {
          signByDefault = true;
          key = cfg.signing.key;
        };
        
        # Ignore common files globally
        ignores = [
          ".DS_Store"
          "*.swp"
          "*.swo"
          "*~"
          ".direnv"
          ".envrc"
          "result"
          "result-*"
        ];
      };
      
      # GitHub CLI
      programs.gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
          prompt = "enabled";
        };
      };
    };
    
    # Git packages
    environment.systemPackages = with pkgs; [
      git
      gh           # GitHub CLI
      lazygit      # Terminal UI for git
    ];
  };
}
