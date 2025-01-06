# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/2bd76009-f981-4cdd-b966-1dc75b09bc56";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" "ssd" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/B98C-9FC7";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [
    {
      device = "/dev/nvme0n1p3";
      discardPolicy = "pages";
      randomEncryption = {
        enable = true;
        allowDiscards = true;
      };
    }
    {
      device = "/dev/nvme1n1p3";
      discardPolicy = "pages";
      randomEncryption = {
        enable = true;
        allowDiscards = true;
      };
    }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp193s0f0np0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp193s0f1np1.useDHCP = lib.mkDefault true;
  # networking.interfaces.eth0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
