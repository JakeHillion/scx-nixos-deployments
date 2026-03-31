let
  users = {
    jake = {
      mbp = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAyFsYYjLZ/wyw8XUbcmkk6OKt2IqLOnWpRE5gEvm3X0V4IeTOL9F4IL79h7FTsPvi2t9zGBL1hxeTMZHSGfrdWaMJkQp94gA1W30MKXvJ47nEVt0HUIOufGqgTTaAn4BHxlFUBUuS7UxaA4igFpFVoPJed7ZMhMqxg+RWUmBAkcgTWDMgzUx44TiNpzkYlG8cYuqcIzpV2dhGn79qsfUzBMpGJgkxjkGdDEHRk66JXgD/EtVasZvqp5/KLNnOpisKjR88UJKJ6/buV7FLVra4/0hA9JtH9e1ecCfxMPbOeluaxlieEuSXV2oJMbQoPP87+/QriNdi/6QuCHkMDEhyGw==";
    };
  };
  jake_users = builtins.attrValues users.jake;

  systems = {
    com.sched-ext = {
      cx = {
        pulsar = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsFwcQh7SK3mHBRdDH+ytlffwASnkiQj8HvvCxNQ4op";
      };
    };
  };
  scx = systems.com.sched-ext;
in
{
  # GitHub fine-grained PATs
  "github/sched_ext-nixos-self-hosted-runners.age".publicKeys = jake_users ++ [ scx.cx.pulsar ];
}
