{ config, pkgs, lib, ... }:

{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  config = {
    system.stateVersion = "24.11";

    networking.hostName = "pulsar";
    networking.domain = "cx.sched-ext.com";

        boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;

    ## Filesystems
    services.btrfs.autoScrub = {
      enable = true;
      interval = "Tue, 02:00";
    };

    ## SSH
    services.openssh.enable = true;
    users.users."root".openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAaj+1br1lsyGfTUiE+w34HfOasExhNRHluYzCNoWN7haoskclFBnFnUjS3d4p5+RmhaSec3WUaf952uoHJ1Cps= jakehillion@jakehillion-mbp"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBC0uKIvvvkzrOcS7AcamsQRFId+bqPwUC9IiUIsiH5oWX1ReiITOuEo+TL9YMII5RyyfJFeu2ZP9moNuZYlE7Bs= jake@jake-mbp"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIzQmTIeccj1vILJPaYf3jO/SFWU5PkspR2xLU/sXInUAfKapfkYC6iDSbbmsXHD6q5F3hwmI3ofGXOqA1kk1MM= jakehillion@devbig002.cln5.facebook.com"
    ];

    ## Networking
    networking = {
      useDHCP = true; # false

      interfaces."enp193s0f0np0" = {
        name = "eth0";
        useDHCP = true;
        ipv6.addresses = [{
          address = "2a01:4f9:3100:1048::2";
          prefixLength = 64;
        }];
      };
      defaultGateway6 = {
	      address = "fe80::1";
	      interface = "eth0";
	    };

      firewall = {
        allowedTCPPorts = lib.mkForce [
          22 # SSH
        ];
        allowedTCPPortRanges = lib.mkForce [ ];
        allowedUDPPorts = lib.mkForce [ ];
        allowedUDPPortRanges = lib.mkForce [ ];

        interfaces."eth0" = {
          allowedTCPPorts = lib.mkForce [
            22 # SSH
          ];
          allowedTCPPortRanges = lib.mkForce [ ];
          allowedUDPPorts = lib.mkForce [ ];
          allowedUDPPortRanges = lib.mkForce [ ];
        };
      };
    };
  };
}
