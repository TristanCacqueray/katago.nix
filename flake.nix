{
  description = "katago";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs"; };
  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { localSystem = "x86_64-linux"; };

      # Models
      humanv0 = pkgs.fetchurl {
        url =
          "https://github.com/lightvector/KataGo/releases/download/v1.15.0/b18c384nbt-humanv0.bin.gz";
        sha256 = "1daav0snigcpmmg9chsc6vz6wwghpflhm9a52anh1zhf9zj4cxv3";
      };

      kata1 = pkgs.fetchurl {
        url =
          "https://media.katagotraining.org/uploaded/networks/models/kata1/kata1-b28c512nbt-s7332806912-d4357057652.bin.gz";
        sha256 = "07cxc5ggjqn06f3ww3xprynzg5diply66npvpqwkggnfvp362s7z";
      };

      # Commands
      katago = "${pkgs.katagoCPU}/bin/katago";
      human-wrapper = pkgs.writeScript "katago-wrapper" ''
        #!/bin/sh
        command=$(echo $1)
        shift
        exec ${pkgs.katagoCPU}/bin/katago $command -human-model ${humanv0} $*
      '';

      # Config
      katrain-config = pkgs.fetchurl {
        url =
          "https://raw.githubusercontent.com/sanderland/katrain/5ccab8e2eedcd046219f8b848ab05ef0d8cec289/katrain/KataGo/analysis_config.cfg";
        sha256 = "158pd2b4wnkl4py0df0x0mp4qr8jv7fkq6mir9s2n3521lk7zaf0";
      };
      human-config-5k = pkgs.fetchurl {
        url =
          "https://raw.githubusercontent.com/lightvector/KataGo/95ffe6d302c958ef3f124c599a1705a47df2195a/cpp/configs/gtp_human5k_example.cfg";
        sha256 = "0mw33pwws83lpkq3ba6bn4fk70pwq5h4jzdc8zkp8f3rl0h48axq";
      };
      human-config-text = builtins.readFile human-config-5k;
      mkHumanConfig = rank:
        pkgs.writeText "katago-${rank}.cfg"
        (builtins.replaceStrings [ "humanSLProfile = preaz_5k" ]
          [ "humanSLProfile = ${rank}" ] human-config-text);

      # Katrain Config
      baseConfig = {
        katago = katago;
        altcommand = "";
        model = "${kata1}";
        config = "${katrain-config}";
        threads = 12;
        max_visits = 750;
        fastfrvisits = 30;
        max_time = 0.8;
        wide_root_noise = 4.0e-2;
        _enable_ownership = true;
      };
      humanConfig = baseConfig // {
        katago = "${human-wrapper}";
        config = builtins.toString (mkHumanConfig "preaz_12k");
      };
    in {
      katrain.engine.default =
        pkgs.writeText "katrain-config.json" (builtins.toJSON baseConfig);
      katrain.engine.human =
        pkgs.writeText "katrain-config.json" (builtins.toJSON humanConfig);
    };
}
