{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # =========================================
  # Boot & Hardware
  # =========================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = true;
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "hpool" ];  
  boot.zfs.devNodes = "/dev/disk/by-id";

  services.smartd.enable = true;

  # =========================================
  # File Systems
  # =========================================
  fileSystems."/mnt/hpool" = {
    device = "hpool";
    fsType = "zfs";
    options = [ "nofail" ];
  };
  fileSystems."/mnt/hpool/data" = { device = "hpool/data"; fsType = "zfs"; };
  fileSystems."/mnt/hpool/media" = { device = "hpool/media"; fsType = "zfs"; };
  fileSystems."/mnt/hpool/backup" = { device = "hpool/backup"; fsType = "zfs"; };
  fileSystems."/mnt/hpool/data/stacks" = { device = "hpool/data/stacks"; fsType = "zfs"; };
  fileSystems."/mnt/hpool/data/stacks/karakeep" = { device = "hpool/data/stacks/karakeep"; fsType = "zfs"; };
  fileSystems."/mnt/hpool/data/stacks/qbittorrent" = { device = "hpool/data/stacks/qbittorrent"; fsType = "zfs"; };
  fileSystems."/mnt/hpool/data/stacks/uptimekuma" = { device = "hpool/data/stacks/uptimekuma"; fsType = "zfs"; };

  services.zfs.autoScrub = {
    enable = true;
    interval = "monthly"; # or "monthly", "daily", etc.
  };
  services.zfs.trim = {
    enable = true;
    interval = "weekly";
  };

  # =========================================
  # Networking
  # =========================================
  networking.hostName = "nixos";
  networking.hostId = "90bfa1ac"; # Required for ZFS
  networking.networkmanager.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };

  services.tailscale.enable = true;

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true; # Set to false if using keys

  # =========================================
  # Localization & Time
  # =========================================
  time.timeZone = "Asia/Manila";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # =========================================
  # Desktop & Graphical
  # =========================================
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.variant = "";
  };
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Remove or comment out Cinnamon/LightDM
  # services.xserver.displayManager.lightdm.enable = true;
  # services.xserver.desktopManager.cinnamon.enable = true;

  services.printing.enable = true;

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # =========================================
  # Packages & Software Environment
  # =========================================
  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;

  programs.firefox.enable = true;

  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    zfs
    docker-compose
    micro
    gnome-software
    gnome-disk-utility
    gsmartcontrol
    smartmontools
    kdePackages.kate
    btop
    restic
    tailscale
    gnome-system-monitor
    google-chrome
    jellyfin-media-player
  ];

  services.flatpak.enable = true;
  systemd.services.configure-flathub-repo = {
    description = "Add Flathub repository";
    wantedBy = [ "multi-user.target" ];
    after = [ "flatpak.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo";
    };
  };

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # This is the critical part for browser integration
    polkitPolicyOwners = [ "user" ];
  };

  # =========================================
  # Users
  # =========================================
  users.users.user = {
    isNormalUser = true;
    description = "user";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      obsidian
      _1password-gui
      cherry-studio
    ];
    shell = pkgs.fish;
  };

  # =========================================
  # Virtualization & Containers
  # =========================================
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Wait for ZFS mounts before starting containers
  systemd.services.docker.after = [ "mnt-hpool.mount" ];
  systemd.services.containerd.after = [ "mnt-hpool.mount" ];

  # =========================================
  # Samba Sharing
  # =========================================
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "NixOS Samba Server";
        "netbios name" = "nixos";
        "security" = "user";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      data = {
        "path" = "/mnt/hpool/data";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
      media = {
        "path" = "/mnt/hpool/media";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
      };
      backup = {
        "path" = "/mnt/hpool/backup";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
      };
    };
  };

  # Ensure Samba starts only after ZFS datasets are mounted
  systemd.services.samba.after = [ "mnt-hpool-data.mount" "mnt-hpool-media.mount" "mnt-hpool-backup.mount" ];
  systemd.services.samba.requires = [ "mnt-hpool-data.mount" "mnt-hpool-media.mount" "mnt-hpool-backup.mount" ];

  # =========================================
  # Other Services
  # =========================================

  systemd.timers."healthchecks-ping" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/3"; # Runs every 3 minutes
      Persistent = true;
    };
  };

  systemd.services."healthchecks-ping" = {
    serviceConfig = {
      Type = "oneshot";
      User = "nobody"; # Change if specific user permissions are needed
    };
    script = ''
      ${pkgs.curl}/bin/curl -fsS --max-time 10 --retry 3 --retry-delay 1 --retry-connrefused "https://hc-ping.com/dbc0f3e9-0425-490c-9719-2ecb7ca9973b" > /dev/null 2>&1
    '';
  };

  # =========================================
  # System Version
  # =========================================
  system.stateVersion = "25.11"; 
}
