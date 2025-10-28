{ lib
, dockerTools
, writeScriptBin
, bashInteractive
, coreutils
, curl
, util-linux
, gnugrep
, gzip
, xz
, sudo
, git
, gnutar
, zstd
, nodejs
, cacert
, github-runner
}:

let
  # Script to run as the unprivileged runner user
  runnerScript = writeScriptBin "run-runner" ''
    #!${bashInteractive}/bin/bash
    set -euo pipefail

    # Determine if token is a PAT or registration token
    if [[ "''${RUNNER_TOKEN}" =~ ^ghp_.*  ]] || [[ "''${RUNNER_TOKEN}" =~ ^github_pat_.* ]]; then
      TOKEN_ARG="--pat"
    else
      TOKEN_ARG="--token"
    fi

    # Configure the runner (ephemeral mode)
    ${github-runner}/bin/config.sh \
      --unattended \
      --url "''${RUNNER_URL}" \
      $TOKEN_ARG "''${RUNNER_TOKEN}" \
      --name "''${RUNNER_NAME}" \
      --labels "''${RUNNER_LABELS}" \
      --work "''${WORK_DIR}/_work" \
      --ephemeral \
      --replace

    # Clear the token from environment before running workflows
    unset RUNNER_TOKEN

    # Run the GitHub runner (will exit after one job in ephemeral mode)
    exec ${github-runner}/bin/Runner.Listener run --startuptype service
  '';

  # Script to start the GitHub runner
  startScript = writeScriptBin "start-runner" ''
    #!${bashInteractive}/bin/bash
    set -euo pipefail

    # Working directory for runner (ephemeral, in container)
    WORK_DIR=/workspace

    # Give runner user ownership of /nix so cachix/install-nix-action can do a single-user install
    chown -R runner /nix

    # Read the GitHub token
    if [[ -z "''${RUNNER_TOKEN_FILE:-}" ]]; then
      echo "Error: RUNNER_TOKEN_FILE environment variable not set"
      exit 1
    fi
    if [[ ! -f "$RUNNER_TOKEN_FILE" ]]; then
      echo "Error: Token file does not exist at: $RUNNER_TOKEN_FILE"
      ls -la "$(dirname "$RUNNER_TOKEN_FILE")" || true
      exit 1
    fi
    echo "Reading token from: $RUNNER_TOKEN_FILE"
    export RUNNER_TOKEN=$(cat "$RUNNER_TOKEN_FILE")
    echo "Token length: ''${#RUNNER_TOKEN}"

    # Configure and run the runner as the runner user
    cd "$WORK_DIR"
    export HOME=/home/runner
    export WORK_DIR
    export USER=runner

    # Drop privileges and run the runner
    echo "Configuring ephemeral GitHub runner..."
    exec ${util-linux}/bin/setpriv --reuid=1000 --regid=1000 --clear-groups --inh-caps=-all \
      ${runnerScript}/bin/run-runner
  '';

  contents = [
    bashInteractive
    coreutils
    curl
    util-linux
    gnugrep
    gzip
    xz
    git
    gnutar
    zstd
    nodejs
    cacert
    github-runner
    runnerScript
    startScript
  ];
in
dockerTools.buildLayeredImage {
  name = "github-runner-nixos";
  tag = "latest";

  inherit contents;

  fakeRootCommands = ''
    mkdir -p ./etc ./home/runner ./workspace ./usr/bin ./tmp ./bin ./root ./etc/pam.d
    chmod 1777 ./tmp
    cat > ./etc/passwd <<EOF
root:x:0:0:System administrator:/root:/bin/bash
runner:x:1000:1000:GitHub Runner:/home/runner:/bin/bash
EOF
    cat > ./etc/group <<EOF
root:x:0:
runner:x:1000:
EOF
    cat > ./etc/sudoers <<EOF
root ALL=(ALL:ALL) ALL
runner ALL=(ALL) NOPASSWD: ALL
EOF
    chmod 0440 ./etc/sudoers

    # Minimal PAM configuration for sudo
    cat > ./etc/pam.d/sudo <<EOF
auth       sufficient pam_permit.so
account    sufficient pam_permit.so
session    sufficient pam_permit.so
EOF

    chown -R 1000:1000 ./home/runner ./workspace
    ln -s ${coreutils}/bin/env ./usr/bin/env

    # Copy sudo and set up permissions
    cp ${sudo}/bin/sudo ./bin/sudo
    chown 0:0 ./bin/sudo
    chmod 4755 ./bin/sudo
  '';

  config = {
    Cmd = [ "${startScript}/bin/start-runner" ];
    Env = [
      "PATH=/bin:${lib.makeBinPath contents}"
      "NIX_SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
  };
}
