# hardware-configuration.nix
# ─────────────────────────────────────────────────────────────
# MSI MAG B850 TOMAHAWK MAX WIFI (MS-7E62)
# AMD Ryzen 7 9800X3D (Zen 5, Granite Ridge, 8C/16T)
# ASUS PRIME GeForce RTX 5070 Ti GAMING OC (GB203, 16 GB GDDR7)
# 64 GB DDR5-6000 Kingston FURY (2x32 GB, KF560C36-32)
# ─────────────────────────────────────────────────────────────
#
# !! UUIDs sind Platzhalter — nach nixos-generate-config einsetzen !!
# !! `blkid` oder `lsblk -f` für die echten Werte !!

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # ──────────────────────────────────────────────
  # Kernel
  # ──────────────────────────────────────────────
  #
  # linuxPackages_latest → Linux 6.19.x (Stand März 2026)
  # Default in NixOS 25.11 ist 6.18 LTS — latest ist besser für:
  #   - RTX 5070 Ti (GB203 / Blackwell) — neueste NVIDIA DRM Fixes
  #   - Realtek RTL8126 5 GbE (r8126, mainline seit ~6.8)
  #   - Qualcomm FastConnect 7800 WiFi 7 (ath12k)
  #   - AMD Zen 5 Scheduler + P-State Optimierungen

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.availableKernelModules = [
    "nvme"           # NVMe SSDs (970 EVO, 990 PRO, 990 EVO Plus)
    "ahci"           # SATA SSDs (860 QVO, 870 QVO)
    "xhci_pci"       # USB 3.x Controller
    "thunderbolt"    # TB Header auf dem Board
    "usbhid"         # USB Tastatur/Maus im initrd
    "sd_mod"         # SCSI Disk
  ];

  boot.initrd.kernelModules = [ ];

  boot.kernelModules = [
    "kvm-amd"        # KVM Virtualisierung
    "nct6775"        # Nuvoton Super I/O — Lüfter/Sensoren (MSI Boards)
    "k10temp"        # AMD CPU Temperatur
  ];

  boot.extraModuleBlacklist = [
    "nouveau"        # Nouveau blocken — NVIDIA proprietary only
  ];

  boot.kernelParams = [
    # ── AMD Zen 5 ──
    "amd_pstate=active"             # P-State EPP Driver

    # ── NVIDIA Blackwell ──
    "nvidia-drm.modeset=1"          # Kernel Modesetting (Wayland Pflicht)
    "nvidia-drm.fbdev=1"            # Framebuffer Device (früher Boot + Wayland)

    # ── Performance / Gaming ──
    "mitigations=off"               # Spectre/Meltdown aus — ~5% mehr FPS
    "preempt=full"                  # Full Preemption — niedrigere Input-Latenz
    "tsc=reliable"                  # TSC als Clocksource (stabil auf Desktop)
    "clocksource=tsc"

    # ── Boot ──
    "quiet"
    "splash"
  ];

  # Qualcomm WiFi 7 + NVIDIA Tuning
  boot.extraModprobeConfig = ''
    # FastConnect 7800: Power Save aus
    options ath12k frame_mode=2
    # NVIDIA: Page Attribute Table für bessere Speicher-Performance
    options nvidia NVreg_UsePageAttributeTable=1
  '';

  # ──────────────────────────────────────────────
  # Firmware
  # ──────────────────────────────────────────────

  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  # ──────────────────────────────────────────────
  # Dateisysteme
  # ──────────────────────────────────────────────
  #
  # Drive-Map:
  #   Samsung 990 PRO  4TB   (NVMe)  → / + /boot         System + Games + Steam
  #   Samsung 990 EVO+ 2TB   (NVMe)  → /data/projects    Code, Builds, Repos
  #   Samsung 970 EVO  1TB   (NVMe)  → /data/scratch     Temp, Downloads
  #   Samsung 860 QVO  4TB   (SATA)  → /data/bulk        Media, Backups, Archive
  #   Samsung 870 QVO  2TB   (SATA)  → /data/extra       Overflow, alte Projekte

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";  # 990 PRO 4TB
    fsType = "ext4";
    options = [ "noatime" "discard=async" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/XXXX-XXXX";  # ESP auf 990 PRO
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  fileSystems."/data/projects" = {
    device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";  # 990 EVO+ 2TB
    fsType = "ext4";
    options = [ "noatime" "discard=async" ];
  };

  fileSystems."/data/scratch" = {
    device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";  # 970 EVO 1TB
    fsType = "ext4";
    options = [ "noatime" "discard=async" ];
  };

  fileSystems."/data/bulk" = {
    device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";  # 860 QVO 4TB
    fsType = "ext4";
    options = [ "noatime" ];
  };

  fileSystems."/data/extra" = {
    device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";  # 870 QVO 2TB
    fsType = "ext4";
    options = [ "noatime" ];
  };

  swapDevices = [
    # 64 GB RAM — Swap nur für Hibernation nötig
    # { device = "/var/lib/swapfile"; size = 32 * 1024; }
  ];

  # ──────────────────────────────────────────────
  # NVIDIA GPU — RTX 5070 Ti (GB203 / Blackwell)
  # ──────────────────────────────────────────────
  #
  # Driver: nvidiaPackages.stable → ~580.x (R570+ nötig für Blackwell)
  # WICHTIG: open = true ist PFLICHT für RTX 50-Serie!
  # Die proprietären Kernel-Module funktionieren NICHT mit Blackwell.
  #
  # Hinweis: Ab NixOS 25.11 zeigt .stable auf den production Branch
  # (~580.x), nicht mehr auf latest. Das ist für die 5070 Ti korrekt.

  hardware.nvidia = {
    open = true;                          # PFLICHT für Blackwell — kein Optional!
    modesetting.enable = true;            # KMS für Wayland
    nvidiaSettings = true;                # nvidia-settings GUI
    powerManagement.enable = false;       # Desktop, kein Suspend nötig
    powerManagement.finegrained = false;  # Nur Laptops (Optimus)
    package = config.boot.kernelPackages.nvidiaPackages.stable;  # ~580.x
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # OpenGL + Vulkan (32-bit für Steam/Wine/Proton)
  # ACHTUNG: hardware.opengl wurde in 24.11 umbenannt zu hardware.graphics!
  hardware.graphics = {
    enable = true;
    enable32Bit = true;   # War vorher hardware.opengl.driSupport32Bit
  };

  # ──────────────────────────────────────────────
  # Platform
  # ──────────────────────────────────────────────

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
