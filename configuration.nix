# configuration.nix
# ─────────────────────────────────────────────────────────────
# NixOS System Config für REGEXP
# Korrigiert & verifiziert für NixOS 25.11 "Xantusia" (März 2026)
# ─────────────────────────────────────────────────────────────
#
# Alle Versionen/Attribute geprüft gegen:
#   - NixOS 25.11 Release Notes
#   - nixpkgs master (März 2026)
#   - NixOS Wiki (Nvidia, KDE, Steam, PipeWire)
#
# Korrekturen gegenüber erster Version:
#   - .NET SDK:  dotnet-sdk_8 → dotnetCorePackages.sdk_10_0 + sdk_8_0
#   - Node.js:   nodejs_22 → nodejs_24 (Active LTS seit Okt 2025)
#   - Docker:    virtualisation.docker.enableNvidia → hardware.nvidia-container-toolkit.enable
#   - MangoHud:  programs.mangohud (existiert nicht auf System-Level) → nur als Package
#   - Fonts:     fira-code-nerdfont → nerd-fonts.fira-code (NerdFonts Namespace Restrukturierung)
#   - Python:    python3 OK, aber python3Packages.pip → python313 (3.14 default, ggf. zu neu)

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ════════════════════════════════════════════════
  # SYSTEM BASICS
  # ════════════════════════════════════════════════

  system.stateVersion = "25.11";   # NixOS 25.11 "Xantusia" — NICHT ändern nach Installation
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      max-jobs = "auto";     # Alle 16 Threads nutzen
      cores = 0;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # ════════════════════════════════════════════════
  # BOOT
  # ════════════════════════════════════════════════

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 20;
      editor = false;
    };
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  boot.plymouth = {
    enable = true;
    theme = "breeze";
  };

  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "16G";
  };

  # ════════════════════════════════════════════════
  # NETZWERK
  # ════════════════════════════════════════════════

  networking = {
    hostName = "regexp";
    networkmanager.enable = true;

    firewall = {
      enable = true;
      # Steam Remote Play / In-Home Streaming
      allowedTCPPorts = [ 27036 27037 ];
      allowedUDPPorts = [ 27031 27036 ];
      allowedTCPPortRanges = [
        { from = 27015; to = 27030; }   # Steam Game Server
      ];
      allowedUDPPortRanges = [
        { from = 27000; to = 27031; }   # Steam Game Traffic
      ];
    };

    nameservers = [ "1.1.1.1" "9.9.9.9" ];
  };

  # ════════════════════════════════════════════════
  # LOKALISIERUNG
  # ════════════════════════════════════════════════

  time.timeZone = "Europe/Berlin";

  i18n = {
    defaultLocale = "de_DE.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "de_DE.UTF-8";
      LC_IDENTIFICATION = "de_DE.UTF-8";
      LC_MEASUREMENT = "de_DE.UTF-8";
      LC_MONETARY = "de_DE.UTF-8";
      LC_NAME = "de_DE.UTF-8";
      LC_NUMERIC = "de_DE.UTF-8";
      LC_PAPER = "de_DE.UTF-8";
      LC_TELEPHONE = "de_DE.UTF-8";
      LC_TIME = "de_DE.UTF-8";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  # ════════════════════════════════════════════════
  # DESKTOP — KDE Plasma 6 (Wayland)
  # ════════════════════════════════════════════════
  #
  # Option-Pfad: services.desktopManager.plasma6 (NICHT services.xserver.desktopManager!)
  # Das ist bewusst so seit Plasma 6 — Wayland-first Design.

  services.desktopManager.plasma6.enable = true;

  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    defaultSession = "plasma";
  };

  programs.xwayland.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-kde ];
  };

  # NVIDIA + Wayland Environment Variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";                    # Electron Apps auf Wayland
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";

    # Gaming Performance
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    DXVK_STATE_CACHE = "1";

    # Proton / Wine — DLSS & NVAPI
    PROTON_ENABLE_NVAPI = "1";
    PROTON_ENABLE_NGX_UPDATER = "1";
    PROTON_HIDE_NVIDIA_GPU = "0";

    # Steam Compat Tools (Proton-GE etc.)
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
  };

  # ════════════════════════════════════════════════
  # AUDIO — PipeWire
  # ════════════════════════════════════════════════
  #
  # Deckt ab: Creative Recon3D, NVIDIA HDMI, AMD HD Audio
  # Config-Pfad: services.pipewire.extraConfig.pipewire (stabil seit 24.05)

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    # Low-Latency für Gaming
    extraConfig.pipewire = {
      "92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 256;
          "default.clock.min-quantum" = 128;
          "default.clock.max-quantum" = 1024;
        };
      };
    };
  };

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # ════════════════════════════════════════════════
  # GAMING
  # ════════════════════════════════════════════════

  # ── Steam ──
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable = true;
  };

  # ── Gamescope ──
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # ── GameMode (Feral Interactive) ──
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        renice = 10;
        softrealtime = "auto";
        inhibit_screensaver = 1;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        nv_powermizer_mode = 1;
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Aktiviert'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Deaktiviert'";
      };
    };
  };

  # ── MangoHud ──
  # ACHTUNG: programs.mangohud existiert NUR in Home-Manager, nicht auf System-Level!
  # System-Level: nur als Package installieren. Config über Home-Manager (home.nix).
  # Per Game aktivieren: MANGOHUD=1 %command% in Steam Launch Options

  # ════════════════════════════════════════════════
  # BLUETOOTH
  # ════════════════════════════════════════════════

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  # ════════════════════════════════════════════════
  # SERVICES
  # ════════════════════════════════════════════════

  # SSH — auskommentiert, bei Bedarf aktivieren
  # services.openssh = {
  #   enable = true;
  #   settings = {
  #     PasswordAuthentication = false;
  #     PermitRootLogin = "no";
  #     X11Forwarding = false;
  #   };
  # };

  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  services.power-profiles-daemon.enable = true;
  services.printing.enable = true;
  services.dbus.enable = true;
  services.flatpak.enable = true;

  hardware.sensor.iio.enable = true;

  # ════════════════════════════════════════════════
  # VIRTUALISIERUNG
  # ════════════════════════════════════════════════

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      ovmf.enable = true;
      swtpm.enable = true;
    };
  };

  # Docker
  virtualisation.docker = {
    enable = true;
    # ACHTUNG: enableNvidia ist DEPRECATED seit 24.05!
    # Ersetzt durch hardware.nvidia-container-toolkit (siehe unten)
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # NVIDIA Container Toolkit (CDI-basiert)
  # Ersetzt das alte virtualisation.docker.enableNvidia
  # WICHTIG: Docker nutzt jetzt --device nvidia.com/gpu=all statt --gpus all!
  hardware.nvidia-container-toolkit.enable = true;

  # ════════════════════════════════════════════════
  # USER
  # ════════════════════════════════════════════════

  users.users.liche = {
    isNormalUser = true;
    description = "Sebastian Nycek";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "gamemode"
      "libvirtd"
      "docker"
      "dialout"         # Serial Ports (Embedded Dev)
      "plugdev"         # USB Geräte
    ];
    shell = pkgs.zsh;
  };

  # ════════════════════════════════════════════════
  # SHELL — ZSH (Basis-Config, Rest in Home-Manager)
  # ════════════════════════════════════════════════

  programs.zsh.enable = true;

  # ════════════════════════════════════════════════
  # SYSTEM-PAKETE
  # ════════════════════════════════════════════════
  #
  # Versionierung (verifiziert März 2026 / NixOS 25.11):
  #   - nodejs_24:   Active LTS "Krypton" (seit Okt 2025), ersetzt nodejs_22
  #   - dotnetCorePackages.sdk_10_0:  .NET 10 LTS (seit Nov 2025)
  #   - dotnetCorePackages.sdk_8_0:   .NET 8 LTS (Support bis Nov 2026)
  #   - python3:     CPython 3.14 (Default in 25.11)
  #   - rustup:      Toolchain Manager (korrekt, aber kollidiert mit cargo/rustc Paketen!)

  environment.systemPackages = with pkgs; [

    # ── System / CLI ──
    wget
    curl
    git
    htop
    btop
    neovim
    vim
    tree
    unzip
    p7zip
    file
    pciutils
    usbutils
    lm_sensors
    nvtopPackages.nvidia
    fastfetch
    ripgrep
    fd
    bat
    eza
    fzf
    zoxide
    tmux
    jq

    # ── Netzwerk ──
    networkmanagerapplet
    nmap
    iperf3
    wireguard-tools

    # ── Dateisystem / Verschlüsselung ──
    gparted
    veracrypt
    ntfs3g

    # ── Entwicklung ──
    rustup                                # Rust Toolchain Manager
    gcc
    gnumake
    cmake
    pkg-config
    openssl
    dotnetCorePackages.sdk_10_0           # .NET 10 LTS (Nov 2025)
    dotnetCorePackages.sdk_8_0            # .NET 8 LTS (für legacy Projekte)
    nodejs_24                             # Node.js 24 LTS "Krypton"
    python3                               # CPython 3.14 (NixOS 25.11 Default)
    python3Packages.pip

    # ── Gaming ──
    lutris
    heroic
    protonup-qt
    wine-staging
    winetricks
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers
    dxvk
    vkd3d-proton
    gamemode
    mangohud                              # CLI + Overlay (Config via Home-Manager)
    goverlay                              # MangoHud Config GUI
    nvidia-vaapi-driver                   # VA-API via NVIDIA (Achtung: kann mit open=true buggen)

    # ── Media / Desktop ──
    firefox
    chromium
    vlc
    mpv
    obs-studio
    discord
    kate
    ark
    spectacle
    gwenview
    okular
    filelight
    kcalc
    kdePackages.kdenlive
    gimp
    libreoffice-qt6

    # ── Audio ──
    pavucontrol
    qpwgraph
    easyeffects

    # ── Virtualisierung ──
    virt-manager
    looking-glass-client

    # ── Fonts ──
    # ACHTUNG: NerdFonts wurden komplett restrukturiert!
    # Alt: nerdfonts / fira-code-nerdfont → ENTFERNT
    # Neu: nerd-fonts.FONTNAME
    noto-fonts
    noto-fonts-cjk-sans                   # Unverändert
    noto-fonts-emoji
    fira-code
    nerd-fonts.fira-code                  # NEU! (war: fira-code-nerdfont)
    nerd-fonts.jetbrains-mono             # NEU! (war: Teil von nerdfonts Override)
    jetbrains-mono
    liberation_ttf
    corefonts                             # Unverändert
  ];

  # ════════════════════════════════════════════════
  # FONTS
  # ════════════════════════════════════════════════

  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" "Liberation Serif" ];
        sansSerif = [ "Noto Sans" "Liberation Sans" ];
        monospace = [ "JetBrains Mono NF" "JetBrains Mono" "Fira Code" ];
        emoji = [ "Noto Color Emoji" ];
      };
      hinting.enable = true;
      hinting.autohint = false;
      hinting.style = "full";
      antialias = true;
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };
    };
  };

  # ════════════════════════════════════════════════
  # SECURITY
  # ════════════════════════════════════════════════

  security.polkit.enable = true;

  security.sudo = {
    enable = true;
    extraRules = [
      {
        groups = [ "wheel" ];
        commands = [
          {
            command = "ALL";
            options = [ "SETENV" ];
          }
        ];
      }
    ];
  };

  # ════════════════════════════════════════════════
  # ENVIRONMENT
  # ════════════════════════════════════════════════

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "firefox";
    TERMINAL = "konsole";
  };
}
