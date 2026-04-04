{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    <home-manager/nixos>
  ];

  # =======================================================================================================================
  # BOOT & HARDWARE
  # =======================================================================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  boot.supportedFilesystems = [ "zfs" "fuse" ];
  boot.zfs.requestEncryptionCredentials = true;
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "hpool" ];  
  boot.zfs.devNodes = "/dev/disk/by-id";

  services.smartd.enable = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      #intel-media-driver # Intel
      #vaapiIntel         # Older Intel
      libva-vdpau-driver         # AMD/Nvidia
      libvdpau-va-gl     # AMD/Nvidia
    ];
  };

  hardware.openrazer.enable = true;

  hardware.openrazer.users = [ "user" ];

  # =======================================================================================================================
  # FILE SYSTEMS
  # =======================================================================================================================
  fileSystems."/mnt/hpool" = { device = "hpool"; fsType = "zfs"; options = [ "nofail" ]; };
  fileSystems."/mnt/hpool/data" = { device = "hpool/data"; fsType = "zfs"; };
  fileSystems."/mnt/hpool/media" = { device = "hpool/media"; fsType = "zfs"; };
  fileSystems."/mnt/hpool/backup" = { device = "hpool/backup"; fsType = "zfs"; };
  #fileSystems."/mnt/hpool/data/stacks" = { device = "hpool/data/stacks"; fsType = "zfs"; };
  #fileSystems."/mnt/hpool/data/stacks/karakeep" = { device = "hpool/data/stacks/karakeep"; fsType = "zfs"; };
  #fileSystems."/mnt/hpool/data/stacks/qbittorrent" = { device = "hpool/data/stacks/qbittorrent"; fsType = "zfs"; };
  #fileSystems."/mnt/hpool/data/stacks/uptimekuma" = { device = "hpool/data/stacks/uptimekuma"; fsType = "zfs"; };

  fileSystems."/Media" = {
    device = "/mnt/hpool/media";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/Downloads" = {
    device = "/mnt/hpool/data/Downloads";
    fsType = "none";
    options = [ "bind" ];
    depends = [ "/mnt/hpool/data" ];
  };

  services.zfs.autoScrub = {
    enable = true;
    interval = "monthly"; # or "monthly", "daily", etc.
  };
  services.zfs.trim = {
    enable = true;
    interval = "weekly";
  };

  systemd.user.services.rclone-mount = {
    description = "rclone mount chesterpelle";
    wantedBy = [ "default.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      ExecStartPre = "/run/current-system/sw/bin/mkdir -p %h/gdrive";
      ExecStart = "${pkgs.rclone}/bin/rclone mount chesterpelle: %h/gdrive --allow-non-empty --vfs-cache-mode full";
      ExecStop = "/run/current-system/sw/bin/fusermount -u %h/gdrive";
      Restart = "on-failure";
      RestartSec = "10s";
      Environment = "PATH=/run/current-system/sw/bin";
    };
  };

  # Required for mounting
  programs.fuse.userAllowOther = true;

  # =======================================================================================================================
  # NETWORKING
  # =======================================================================================================================
  networking.hostName = "nixos";
  networking.hostId = "90bfa1ac"; # Required for ZFS
  networking.networkmanager.enable = true;
  networking.firewall = {
    allowedTCPPorts = [ 853 5443 8080 ];
    allowedUDPPorts = [ 853 784 8853 5443 ];
  };

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

  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';

  # =======================================================================================================================
  # LOCALIZATION & TIME
  # =======================================================================================================================
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

  # =======================================================================================================================
  # DESKTOP & GRAPHICAL
  # =======================================================================================================================
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.variant = "";
  };
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

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

  services.displayManager.sddm.settings = {
    General = {
      # Enable HiDPI support
      EnableHiDPI = true;
    };
  };

# Force specific scaling for Wayland-based SDDM (if using)
services.displayManager.sddm.wayland.enable = true;

  # =======================================================================================================================
  # PACKAGES & SOFTWARE ENVIRONMENT
  # =======================================================================================================================
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;

  programs.firefox.enable = true;

  environment.variables.TERMINAL = "ghostty";

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
    restic-browser
    tailscale
    gnome-system-monitor
    google-chrome
    jellyfin-media-player
    freefilesync
    apacheHttpd
    docker-buildx
    nodejs_24
    corepack
    pnpm
    vorta
    rclone #cmd: rclone config
    ghostty
    fzf
    aichat
    git
    ffmpeg-full
    libva-utils
    vlc
    fuse
    appimage-run
    sunshine
    wget
    openssl
    input-remapper
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

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  environment.variables.VORTA_ALLOW_SHELL = "1";

  environment.shellAliases = {
    docs = "cd ~/Documents";
    backuphome = "sudo btrfs subvolume snapshot -r /home /home_snapshot && sudo btrfs send /home_snapshot | zstd -T0 -3 > /mnt/hpool/backup/btrfs/home_$(date +%Y-%m-%d_%H%M).img.zst && sudo btrfs subvolume delete /home_snapshot";
    editconf = "sudo nano /etc/nixos/configuration.nix";
    saveconf = "mkdir -p ~/backup && cp /etc/nixos/configuration.nix ~/backup/configuration.nix.$(date +%Y-%m-%d_%H%M%S).backup";
    rebuilds = "sudo nixos-rebuild switch";
    rebuildb = "sudo nixos-rebuild boot && reboot";
    log = "tail -f /var/log/syslog";
    myflatpakstarters = "flatpak install flathub com.cherry_ai.CherryStudio com.github.tchx84.Flatseal -y";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # This fixes the setcap error
    openFirewall = true; # Optional: opens ports 47984-48010
  };

  # =======================================================================================================================
  # USERS
  # =======================================================================================================================
  users.users.user = {
    isNormalUser = true;
    description = "user";
    extraGroups = [ "networkmanager" "wheel" "docker" "webdav" "openrazer" ];
    packages = with pkgs; [
      obsidian
      _1password-gui
      whatsapp-electron
      haruna
      moonlight-qt
      vscodium
      devtoolbox
    ];
    shell = pkgs.bash;
    linger = true;
  };

  users.users.nginx.extraGroups = [ "webdav" ];

  users.groups.webdav = {};

  home-manager.users.user = { pkgs, ... }: {
    home.stateVersion = "25.11";
  };

  # =======================================================================================================================
  # VIRTUALIZATION & CONTAINERS
  # =======================================================================================================================
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Wait for ZFS mounts before starting containers
  systemd.services.docker.after = [ "mnt-hpool.mount" ];
  systemd.services.containerd.after = [ "mnt-hpool.mount" ];

  # =======================================================================================================================
  # SAMBA SHARING
  # =======================================================================================================================
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

  # =======================================================================================================================
  # OTHER SERVICES
  # =======================================================================================================================

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

  systemd.services.nginx.serviceConfig = {
    ReadWritePaths = [ "/srv/webdav" "/var/cache/nginx/client_body" ];
    ProtectSystem = lib.mkForce "full";
  };


  systemd.tmpfiles.rules = [
    "d /var/cache/nginx/client_body 0700 nginx webdav -"
    "d /srv/webdav 0775 nginx webdav -"
  ];

  services.nginx = {
    enable = true;
    group = "webdav"; # Crucial for folder permissions
    package = pkgs.nginx.override {
      withDav = true;
      withDavExt = true;
    };

    virtualHosts."10.0.0.2" = {
      # Moved inside virtualHost to ensure it's applied to the auth scope
      basicAuthFile = "/etc/nginx/htpasswd"; #command: nix-shell -p apacheHttpd --run "htpasswd -c /etc/nginx/htpasswd <username>"
      listen = [{ addr = "10.0.0.2"; port = 8080; }];

      locations."/dav/" = {
        alias = "/srv/webdav/";
        extraConfig = ''
          dav_methods PUT DELETE MKCOL COPY MOVE;
          dav_ext_methods PROPFIND OPTIONS;
          dav_access user:rw group:rw all:r;
          create_full_put_path on;
          autoindex on;
          client_max_body_size 0;
          client_body_temp_path /var/cache/nginx/client_body;
          add_header 'Dav' '1, 2' always;
        '';
      };
    };
  };

  # =======================================================================================================================
  # SYSTEM VERSION
  # =======================================================================================================================
  system.stateVersion = "25.11"; 
}
