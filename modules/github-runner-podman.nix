{ config, pkgs, lib, ... }:

let
  cfg = config.services.github-runners-podman;

  # Build the OCI container image for the GitHub runner
  runnerImage = pkgs.callPackage ../pkgs/github-runner-image.nix { };

  # Function to create a runner service
  mkRunnerService = i:
    let
      runnerName = "${config.networking.hostName}-podman-${builtins.toString i}";
    in {
      name = "github-runner-podman-${builtins.toString i}";
      value = {
        description = "GitHub Actions Runner (Podman) ${runnerName}";
        after = [ "network.target" "podman.service" ];
        wants = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "10s";

          # Run as dedicated user (rootless containers)
          User = "github-runner-podman";
          Group = "github-runner-podman";
          SupplementaryGroups = [ "kvm" ];

          # newuidmap/newgidmap are in /run/wrappers/bin with setuid wrappers on NixOS
          Environment = "PATH=/run/wrappers/bin";

          ExecStart = ''
            ${pkgs.podman}/bin/podman run \
              --rm \
              --name ${runnerName} \
              --hostname ${runnerName} \
              --volume ${config.age.secrets."github/sched_ext-nixos-self-hosted-runners-podman".path}:/secrets/github-token:ro \
              --device /dev/kvm \
              --env RUNNER_NAME=${runnerName} \
              --env RUNNER_URL=https://github.com/sched-ext \
              --env RUNNER_TOKEN_FILE=/secrets/github-token \
              --env RUNNER_LABELS=podman:minimal \
              --env RUNNER_EPHEMERAL=true \
              docker-archive:${runnerImage}
          '';

          ExecStop = "${pkgs.podman}/bin/podman stop -t 10 ${runnerName}";
        };
      };
    };
in
{
  options.services.github-runners-podman = {
    enable = lib.mkEnableOption "GitHub Actions runners in Podman containers";

    numRunners = lib.mkOption {
      type = lib.types.int;
      description = "Number of Podman-based GitHub runners to start";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure Podman is enabled
    virtualisation.podman.enable = true;

    # Create dedicated user for running Podman containers
    users.users.github-runner-podman = {
      isSystemUser = true;
      group = "github-runner-podman";
      description = "GitHub Actions Podman Runner";
      home = "/var/lib/github-runner-podman";
      createHome = true;
      subUidRanges = [{ startUid = 100000; count = 65536; }];
      subGidRanges = [{ startGid = 100000; count = 65536; }];
    };

    users.groups.github-runner-podman = {};

    # Create systemd services for each runner
    systemd.services = builtins.listToAttrs
      (builtins.genList mkRunnerService cfg.numRunners);
  };
}
