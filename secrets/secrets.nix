let
  users = {
    jake = {
      mbp = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAyFsYYjLZ/wyw8XUbcmkk6OKt2IqLOnWpRE5gEvm3X0V4IeTOL9F4IL79h7FTsPvi2t9zGBL1hxeTMZHSGfrdWaMJkQp94gA1W30MKXvJ47nEVt0HUIOufGqgTTaAn4BHxlFUBUuS7UxaA4igFpFVoPJed7ZMhMqxg+RWUmBAkcgTWDMgzUx44TiNpzkYlG8cYuqcIzpV2dhGn79qsfUzBMpGJgkxjkGdDEHRk66JXgD/EtVasZvqp5/KLNnOpisKjR88UJKJ6/buV7FLVra4/0hA9JtH9e1ecCfxMPbOeluaxlieEuSXV2oJMbQoPP87+/QriNdi/6QuCHkMDEhyGw==";
      "devbig002.cln5" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDdAkIsWNFrPJyfg2YWGZcDIfQg0V9cGnnEJvC0yht2EmmxUSpRFl2PwnHANf86tybU/i92KIDYDpjO1ciyArLJwmc4OayEThVVeq/j4BFznrfMuEdUqqsOut0bGdhKwnxdAW7APkWMIu1DpXMjWytAt2QzGyYlFx1c431NruHudlHnO1yljQE6CJhKO9CPc2ebQg33yjrrbUVsIrn6K10RkenCsFQn/I0rmxBsKZ1rvPs3w6Mi1aD+LbcTR3iORs/6KVKtyRn3iLAj1hl7Vr73SE2fYuSVrvzr43X2Ph12b00Gb03r/NPMqGeXPBBhOuZPfQJfgT49GfSSedB0TK9feQTlhHVkL882aVfrAMFiGaBQcABysOTNO8SEEhNNbx5W01eeknRsVz5v4iLpQxQ29igyoE0XjAtjpHjkvjNC7xwGAf658L72FDD21EDdEAUO9GV2VgqPOgsSI5yN+G7baxVSrRKUpAZcaSX2QAWx0gkHszGvCcugulFrcSKugMs=";
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
