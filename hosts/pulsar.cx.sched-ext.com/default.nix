{ config, pkgs, lib, ... }:

let
  numRunners = 4;
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  config = {
    system.stateVersion = "24.11";

    networking.hostName = "pulsar";
    networking.domain = "cx.sched-ext.com";

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    ## Kernel
    ### Server hardware needs a recent kernel. Update to at least 6.12 else stable.
    boot.kernelPackages =
      if pkgs.linuxPackages.kernelAtLeast "6.12" then pkgs.linuxPackages
      else pkgs.linuxPackages_latest;

    ## Filesystems
    services.btrfs.autoScrub = {
      enable = true;
      interval = "Tue, 02:00";
    };

    ## GitHub Runners
    age.secrets."github/sched_ext-nixos-self-hosted-runners".file = ../../secrets/github/sched_ext-nixos-self-hosted-runners.age;
    services.github-runners = builtins.listToAttrs
      (builtins.genList
        (i: {
          name = "${config.networking.hostName}-${builtins.toString i}";
          value =
            let
              workDir = "/var/tmp/github-runner-${config.networking.hostName}-${builtins.toString i}";
            in
            {
              enable = true;
              url = "https://github.com/sched-ext";
              tokenFile = config.age.secrets."github/sched_ext-nixos-self-hosted-runners".path;
              replace = true;

              inherit workDir;
              serviceOverrides.ReadWritePaths = [ workDir ];

              extraPackages = with pkgs; [
                git
              ];
            };
        })
        numRunners);
    systemd.tmpfiles.rules = lib.lists.flatten (builtins.genList
      (i: [
        "e! /var/tmp/github-runner-${config.networking.hostName}-${builtins.toString i} - - - 0"
        "d  /var/tmp/github-runner-${config.networking.hostName}-${builtins.toString i} 0700 root root -"
      ])
      numRunners);


    ## System packages
    environment = {
      systemPackages = with pkgs; [
        git
        htop
        nix
        vim
      ];
      variables.EDITOR = "vim";

      shellAliases = {
        "nixos-rebuild" = "nixos-rebuild --flake \"/etc/nixos#${config.networking.fqdn}\"";
      };
    };

    ## SSH
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
      };
    };

    users = {
      mutableUsers = false;

      users.scx = {
        isNormalUser = true;
        extraGroups = [ "wheel" ]; # enable sudo

        openssh.authorizedKeys.keys = [
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAaj+1br1lsyGfTUiE+w34HfOasExhNRHluYzCNoWN7haoskclFBnFnUjS3d4p5+RmhaSec3WUaf952uoHJ1Cps= jakehillion@jakehillion-mbp"
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBC0uKIvvvkzrOcS7AcamsQRFId+bqPwUC9IiUIsiH5oWX1ReiITOuEo+TL9YMII5RyyfJFeu2ZP9moNuZYlE7Bs= jake@jake-mbp"
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIzQmTIeccj1vILJPaYf3jO/SFWU5PkspR2xLU/sXInUAfKapfkYC6iDSbbmsXHD6q5F3hwmI3ofGXOqA1kk1MM= jakehillion@devbig002.cln5.facebook.com"
        ];
      };
    };
    security.sudo.wheelNeedsPassword = false;

    ## General settings
    time.timeZone = "Etc/UTC"; # UTC for global consistency

    ## Nix settings
    hardware.enableAllFirmware = true;
    nix = {
      settings.experimental-features = [ "nix-command" "flakes" ];
      settings = {
        auto-optimise-store = true;
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 90d";
      };
    };
    nixpkgs.config.allowUnfree = true;

    system.autoUpgrade = {
      enable = true;
      allowReboot = true;

      flake = "github:JakeHillion/scx-nixos-deployments#${config.networking.fqdn}";
      flags = [ "--print-build-logs" ];

      dates = "Mon-Fri 13:00";
      randomizedDelaySec = "60min";
    };

    ## Networking
    networking = {
      useDHCP = false;

      interfaces."enp193s0f0np0" = {
        useDHCP = true;
        ipv6.addresses = [{
          address = "2a01:4f9:3100:1048::2";
          prefixLength = 64;
        }];
      };

      defaultGateway6 = {
        address = "fe80::1";
        interface = "enp193s0f0np0";
      };

      firewall = {
        allowedTCPPorts = lib.mkForce [
          22 # SSH
        ];
        allowedTCPPortRanges = lib.mkForce [ ];
        allowedUDPPorts = lib.mkForce [ ];
        allowedUDPPortRanges = lib.mkForce [ ];

        interfaces."enp193s0f0np0" = {
          allowedTCPPorts = lib.mkForce [ ];
          allowedTCPPortRanges = lib.mkForce [ ];
          allowedUDPPorts = lib.mkForce [ ];
          allowedUDPPortRanges = lib.mkForce [ ];
        };
      };
    };
  };
}
