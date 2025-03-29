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
          "https://media.katagotraining.org/uploaded/networks/models/kata1/kata1-b28c512nbt-s8476434688-d4668249792.bin.gz";
        sha256 = "sha256-UKp7uFOXFzuOAc6qiowKv+pSZf2bQIf43gNqCEd5AaA=";
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
          "https://raw.githubusercontent.com/sanderland/katrain/3fa41ff4e08f5088a6e48322f2d967d62cf39cac/katrain/KataGo/analysis_config.cfg";
        sha256 = "sha256-wKl/Jg2iDCt0yrEaPN3ZEmVMbgUduAb8JXRaTpZoF5U=";
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
          [ "humanSLProfile = ${rank}" ] (human-config-text + ''

            numAnalysisThreads = 12
          ''));

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
      humanConfig12k = baseConfig // {
        katago = "${human-wrapper}";
        config = builtins.toString (mkHumanConfig "preaz_12k");
      };
      humanConfig1d = baseConfig // {
        katago = "${human-wrapper}";
        config = builtins.toString (mkHumanConfig "preaz_1d");
      };
    in {
      katrain.engine.default =
        pkgs.writeText "katrain-config.json" (builtins.toJSON baseConfig);
      katrain.engine.human1d =
        pkgs.writeText "katrain-config.json" (builtins.toJSON humanConfig1d);
      katrain.engine.human12k =
        pkgs.writeText "katrain-config.json" (builtins.toJSON humanConfig12k);
    };
}
