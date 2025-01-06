{
  disko.devices = {
    disk = {
      disk0 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            swap = {
              size = "128G";
              content = {
                type = "swap";
                randomEncryption = true;
                discardPolicy = "both";
              };
            };

            root = {
              # Empty partition for btrfs raid
              size = "100%";
            };
          };
        };
      };

      disk1 = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            swap = {
              size = "128G";
              content = {
                type = "swap";
                randomEncryption = true;
                discardPolicy = "both";
              };
            };

            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-d raid1"
                  "/dev/nvme0n1p2"
                ];

                mountpoint = "/";
                mountOptions = [ "compress=zstd" "noatime" "ssd" ];
              };
            };
          };
        };
      };
    };

    nodev = {
      "/tmp" = {
        fsType = "tmpfs";
      };
    };
  };
}
