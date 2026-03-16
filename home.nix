# home.nix
# ─────────────────────────────────────────────────────────────
# Home-Manager Konfiguration für User: liche
# Verwaltet: Shell, Git, MangoHud, Dotfiles, User-Level Packages
# ─────────────────────────────────────────────────────────────
#
# Vorteile gegenüber System-Level:
#   - Kein sudo nötig zum Ändern
#   - User-spezifische Config getrennt vom System
#   - MangoHud hat hier einen echten NixOS-Option (programs.mangohud)
#   - Dotfiles deklarativ verwaltet

{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.11";
  home.username = "liche";
  home.homeDirectory = "/home/liche";

  # ════════════════════════════════════════════════
  # ZSH
  # ════════════════════════════════════════════════

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "git"
        "docker"
        "rust"
        "dotnet"
        "sudo"          # ESC ESC → sudo voranstellen
        "history"
        "dirhistory"
        "fzf"           # Fuzzy Finder Integration
        "zoxide"        # z / zi Smart-CD
      ];
    };

    shellAliases = {
      # Moderne CLI-Tools
      ll = "eza -la --icons --group-directories-first";
      ls = "eza --icons --group-directories-first";
      cat = "bat";
      grep = "rg";
      find = "fd";

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # NixOS Management
      nixreb = "sudo nixos-rebuild switch --flake ~/nixos#regexp";
      nixtest = "sudo nixos-rebuild test --flake ~/nixos#regexp";
      nixboot = "sudo nixos-rebuild boot --flake ~/nixos#regexp";
      nixedit = "nvim ~/nixos/configuration.nix";
      nixhome = "nvim ~/nixos/home.nix";
      nixclean = "sudo nix-collect-garbage -d && sudo nixos-rebuild switch --flake ~/nixos#regexp";
      nixsearch = "nix search nixpkgs";
      nixup = "cd ~/nixos && nix flake update && nixreb";

      # System
      gpu = "nvidia-smi";
      temps = "sensors";
      ports = "sudo ss -tulnp";
      disk = "df -h";
      mem = "free -h";

      # Docker (beachte: --device nvidia.com/gpu=all statt --gpus all!)
      dps = "docker ps";
      dpa = "docker ps -a";
      dlog = "docker logs -f";
      dexec = "docker exec -it";

      # Git Shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph -20";
      gd = "git diff";
    };

    initExtra = ''
      # Zoxide initialisieren (smartes cd)
      eval "$(zoxide init zsh)"

      # FZF Keybindings
      export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
      export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"

      # Rust
      export PATH="$HOME/.cargo/bin:$PATH"

      # .NET
      export DOTNET_CLI_TELEMETRY_OPTOUT=1

      # Custom Prompt Farbe für SSH Sessions
      if [ -n "$SSH_CLIENT" ]; then
        export PROMPT="%{$fg[red]%}[SSH] $PROMPT"
      fi
    '';
  };

  # ════════════════════════════════════════════════
  # GIT
  # ════════════════════════════════════════════════

  programs.git = {
    enable = true;
    userName = "Sebastian Nycek";
    userEmail = "";  # ← Hier deine E-Mail einsetzen
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core = {
        editor = "nvim";
        autocrlf = "input";
      };
      diff.colorMoved = "default";
      merge.conflictstyle = "diff3";
      rerere.enabled = true;           # Reuse Recorded Resolution
    };
    delta = {
      enable = true;                   # Besserer Diff-Viewer
      options = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
      };
    };
  };

  # ════════════════════════════════════════════════
  # MANGOHUD — Config über Home-Manager
  # ════════════════════════════════════════════════
  #
  # programs.mangohud existiert NUR hier, nicht auf System-Level.
  # Aktivieren per Game: MANGOHUD=1 %command% in Steam Launch Options
  # Oder: mangohud /pfad/zum/game

  programs.mangohud = {
    enable = true;
    enableSessionWide = false;  # Nur per Game, nicht global
    settings = {
      # ── Layout ──
      position = "top-left";
      font_size = 20;
      round_corners = 8;
      background_alpha = "0.5";

      # ── Was angezeigt wird ──
      fps = true;
      frametime = true;
      frame_timing = true;
      gpu_stats = true;
      gpu_temp = true;
      gpu_power = true;
      gpu_mem_temp = true;
      gpu_fan = true;
      cpu_stats = true;
      cpu_temp = true;
      cpu_power = true;
      ram = true;
      vram = true;
      gamemode = true;         # Zeigt ob GameMode aktiv ist
      vulkan_driver = true;
      wine = true;             # Zeigt Wine/Proton Version
      resolution = true;

      # ── Logging ──
      output_folder = "/home/liche/mangohud_logs";
      # F2 zum Logging starten/stoppen (default)
    };
  };

  # ════════════════════════════════════════════════
  # VS CODE — via Home-Manager
  # ════════════════════════════════════════════════
  #
  # Das Package selbst wird system-level installiert (vscode.fhs in configuration.nix)
  # weil die FHS-Variante root braucht. Hier konfigurieren wir Settings + Extensions.
  #
  # Extensions installieren:
  #   Option A: Einfach im VS Code Marketplace installieren (funktioniert dank FHS)
  #   Option B: Deklarativ über extensions = [ ... ] (reproduzierbar, aber manueller)
  #
  # Für volle deklarative Extension-Verwaltung → nix-vscode-extensions Flake Input nutzen

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;   # FHS-kompatibel, Extensions funktionieren
    # mutableExtensionsDir = true;  # true = Extensions auch manuell installierbar (default)

    userSettings = {
      # ── Editor ──
      "editor.fontSize" = 14;
      "editor.fontFamily" = "'JetBrains Mono NF', 'Fira Code', 'Droid Sans Mono', monospace";
      "editor.fontLigatures" = true;
      "editor.formatOnSave" = true;
      "editor.minimap.enabled" = false;
      "editor.renderWhitespace" = "boundary";
      "editor.bracketPairColorization.enabled" = true;
      "editor.smoothScrolling" = true;
      "editor.cursorBlinking" = "smooth";
      "editor.cursorSmoothCaretAnimation" = "on";
      "editor.tabSize" = 4;
      "editor.detectIndentation" = true;

      # ── Terminal ──
      "terminal.integrated.fontFamily" = "'JetBrains Mono NF'";
      "terminal.integrated.fontSize" = 13;
      "terminal.integrated.defaultProfile.linux" = "zsh";

      # ── Files ──
      "files.autoSave" = "afterDelay";
      "files.autoSaveDelay" = 1000;
      "files.trimTrailingWhitespace" = true;
      "files.insertFinalNewline" = true;
      "files.trimFinalNewlines" = true;

      # ── Workbench ──
      "workbench.colorTheme" = "Default Dark+";  # Anpassen nach Geschmack
      "workbench.iconTheme" = "vs-seti";
      "workbench.startupEditor" = "none";

      # ── Telemetry aus ──
      "telemetry.telemetryLevel" = "off";
      "redhat.telemetry.enabled" = false;

      # ── Wayland ──
      # NIXOS_OZONE_WL=1 ist schon in sessionVariables gesetzt
      "window.titleBarStyle" = "custom";

      # ── Git ──
      "git.autofetch" = true;
      "git.confirmSync" = false;
      "git.enableSmartCommit" = true;

      # ── Rust ──
      "rust-analyzer.check.command" = "clippy";

      # ── C# / .NET ──
      "dotnetAcquisitionExtension.existingDotnetPath" = [
        {
          "extensionId" = "ms-dotnettools.csharp";
          "path" = "/run/current-system/sw/bin/dotnet";
        }
      ];

      # ── Nix ──
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
      "nix.serverSettings" = {
        "nil" = {
          "formatting" = {
            "command" = [ "nixfmt" ];
          };
        };
      };
    };

    # Deklarative Extensions — die wichtigsten vorinstalliert
    # Weitere Extensions können trotzdem manuell im Marketplace installiert werden
    extensions = with pkgs.vscode-extensions; [
      # Nix
      jnoortheen.nix-ide

      # Rust
      rust-lang.rust-analyzer

      # C# / .NET
      ms-dotnettools.csharp
      ms-dotnettools.csdevkit

      # Python
      ms-python.python
      ms-python.debugpy

      # Docker
      ms-azuretools.vscode-docker

      # Git
      eamodio.gitlens

      # Remote
      ms-vscode-remote.remote-ssh

      # Allgemein
      esbenp.prettier-vscode
      dbaeumer.vscode-eslint
      usernamehw.errorlens
      pkief.material-icon-theme
    ];
  };

  # ════════════════════════════════════════════════
  # FZF
  # ════════════════════════════════════════════════

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # ════════════════════════════════════════════════
  # BAT (cat Replacement)
  # ════════════════════════════════════════════════

  programs.bat = {
    enable = true;
    config = {
      theme = "Dracula";
      pager = "less -FR";
    };
  };

  # ════════════════════════════════════════════════
  # BTOP
  # ════════════════════════════════════════════════

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "dracula";
      theme_background = false;
      vim_keys = true;
      shown_boxes = "cpu mem net proc gpu0";
      update_ms = 1000;
    };
  };

  # ════════════════════════════════════════════════
  # DIRENV — Automatische Nix DevShells pro Projekt
  # ════════════════════════════════════════════════

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;   # Cached nix develop Shells
    enableZshIntegration = true;
  };

  # ════════════════════════════════════════════════
  # STARSHIP PROMPT (Optional — Alternative zu agnoster)
  # ════════════════════════════════════════════════
  # Auskommentieren und oh-my-zsh theme entfernen wenn gewünscht
  #
  # programs.starship = {
  #   enable = true;
  #   enableZshIntegration = true;
  #   settings = {
  #     add_newline = false;
  #     character = {
  #       success_symbol = "[➜](bold green)";
  #       error_symbol = "[✗](bold red)";
  #     };
  #     nix_shell = {
  #       symbol = "❄️ ";
  #       format = "via [$symbol$state]($style) ";
  #     };
  #   };
  # };

  # ════════════════════════════════════════════════
  # XDG DIRECTORIES
  # ════════════════════════════════════════════════

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "$HOME/Desktop";
      documents = "$HOME/Dokumente";
      download = "$HOME/Downloads";
      music = "$HOME/Musik";
      pictures = "$HOME/Bilder";
      videos = "$HOME/Videos";
      templates = "$HOME/Vorlagen";
      publicShare = "$HOME/Öffentlich";
    };
  };

  # ════════════════════════════════════════════════
  # ZUSÄTZLICHE USER-PAKETE
  # ════════════════════════════════════════════════
  #
  # Pakete die nur für diesen User sind, nicht systemweit

  home.packages = with pkgs; [
    delta              # Git Diff Tool (wird von programs.git.delta genutzt)
    lazygit            # Terminal Git UI
    tokei              # Code Statistics
    hyperfine          # Benchmarking Tool
    tealdeer           # tldr Pages (kurze man Alternativen)
    duf                # Modernes df
    dust               # Modernes du
    procs              # Modernes ps
    bottom             # Noch ein System Monitor
    nil                # Nix Language Server (für VS Code nix-ide)
    nixfmt-rfc-style   # Nix Formatter (für VS Code nix-ide)
  ];
}
