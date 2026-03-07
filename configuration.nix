# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = true;
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "hpool" ];  
  boot.zfs.devNodes = "/dev/disk/by-id";
  networking.hostId = "90bfa1ac"; # Required for ZFS, generate a unique ID

  fileSystems."/mnt/hpool" = {
    device = "hpool";
    fsType = "zfs";
    options = [ "nofail" ]; # Optional: allows boot even if drive is unplugged
  };

  # Since you use these for Samba, listing them here ensures 
  # Samba doesn't start until the folders actually exist.
  fileSystems."/mnt/hpool/data" = { device = "hpool/data"; fsType = "zfs"; };
  fileSystems."/mnt/hpool/media" = { device = "hpool/media"; fsType = "zfs"; };
  fileSystems."/mnt/hpool/backup" = { device = "hpool/backup"; fsType = "zfs"; };

  
  # Enable ZFS support
  # boot.zfs.enable = true;
  
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Manila";

  # Select internationalisation properties.
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Cinnamon Desktop Environment.
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.cinnamon.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.user = {
    isNormalUser = true;
    description = "user";
    extraGroups = [ "networkmanager" "wheel" "docker"];
    packages = with pkgs; [
    #  thunderbird
      obsidian
      _1password-gui
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
    zfs
    docker-compose
    micro
    pkgs.gnome-software
    pkgs.gnome-disk-utility
    gsmartcontrol
    smartmontools
    pkgs.flatseal
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  virtualisation.docker = {
    enable = true;
    # Enable Docker daemon on boot
    enableOnBoot = true;
    # Storage driver (optional)
    # storageDriver = "overlay2";
    # Auto-start containers (optional)
    # autoPrune.enable = true;
    # Extra package options
    # package = pkgs.docker_24; # Specify version if needed
  };

  systemd.services.docker.after = [ "mnt-hpool.mount" ];
  systemd.services.containerd.after = [ "mnt-hpool.mount" ];

  services.samba = {
    enable = true;
    openFirewall = true;
    
    # All configuration now goes inside 'settings'
    settings = {
      # The "global" section replaces extraConfig
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "NixOS Samba Server";
        "netbios name" = "nixos";
        "security" = "user";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };

      # Your Shares
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

  # Optional: Enable mDNS (Avahi) so you can find the server via "nixos.local"
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };

  systemd.services.samba.after = [ "mnt-hpool-data.mount" "mnt-hpool-media.mount" "mnt-hpool-backup.mount" ];
  systemd.services.samba.requires = [ "mnt-hpool-data.mount" "mnt-hpool-media.mount" "mnt-hpool-backup.mount" ];

  # Enable Flatpak support
  services.flatpak.enable = true;
  
  # Add Flathub repository (this is the correct syntax for NixOS 25.11)
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

  services.smartd.enable = true;

}
