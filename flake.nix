{
  description = "prometheus dyson exporter";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:

    {
      nixosModules.default = self.nixosModules.dyson-exporter;
      nixosModules.dyson-exporter = { lib, pkgs, config, ... }:
        with lib;

        let cfg = config.services.dyson-exporter;
        in
        {

          options.services.dyson-exporter = {

            enable = mkEnableOption "dyson-exporter";

            configure-prometheus = mkEnableOption "enable dyson-exporter in prometheus";

            port = mkOption {
              type = types.str;
              default = "8096";
              description = "Port under which dyson-exporter is accessible.";
            };

            listen = mkOption {
              type = types.str;
              default = "localhost";
              example = "127.0.0.1";
              description = "Address under which dyson-exporter is accessible.";
            };

            envfile = mkOption {
              type = types.str;
              default = "/var/src/secrets/dyson-exporter/envfile";
              description = ''
                The location of the envfile containing secrets
              '';
            };

            user = mkOption {
              type = types.str;
              default = "dyson-exporter";
              description = "User account under which dyson-exporter runs.";
            };

            group = mkOption {
              type = types.str;
              default = "dyson-exporter";
              description = "Group under which dyson-exporter runs.";
            };

          };

          config = mkIf cfg.enable {

            systemd.services.dyson-exporter = {
              description = "A dyson metrics exporter";
              wantedBy = [ "multi-user.target" ];
              serviceConfig = mkMerge [{
                EnvironmentFile = [ cfg.envfile ];
                User = cfg.user;
                Group = cfg.group;
                ExecStart = "${self.packages."${pkgs.system}".dyson_exporter}/bin/dyson_exporter";
                Restart = "on-failure";
                Environment = [
                  "dyson_exporter_port=${cfg.port}"
                  "dyson_exporter_listen=${cfg.listen}"
                ];
              }];
            };

            users.users = mkIf (cfg.user == "dyson-exporter") {
              dyson-exporter = {
                isSystemUser = true;
                group = cfg.group;
                description = "dyson-exporter system user";
              };
            };

            users.groups =
              mkIf (cfg.group == "dyson-exporter") { dyson-exporter = { }; };

            services.prometheus = mkIf cfg.configure-prometheus {
              scrapeConfigs = [{
                job_name = "dyson";
                scrape_interval = "15s";
                metrics_path = "/metrics";
                static_configs = [{
                  targets = [ "${cfg.listen}:${cfg.port}" ];
                }];
              }];
            };

          };
          meta = { maintainers = with lib.maintainers; [ mayniklas ]; };
        };
    }

    //

    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};

      in
      rec {

        formatter = pkgs.nixpkgs-fmt;

        packages = flake-utils.lib.flattenTree rec {

          # libdyson is the only python lib needed that is not in nixpkgs
          libdyson = with pkgs.python3Packages;
            buildPythonPackage rec {
              pname = "libdyson";
              version = "0.8.11";

              propagatedBuildInputs = [ paho-mqtt zeroconf requests cryptography attrs ];
              src = pkgs.fetchFromGitHub {
                owner = "shenxn";
                repo = "libdyson";
                rev = "v${version}";
                sha256 = "sha256-u+7hw7DLgfPjQbm+2TiKocZqSLFTeNaXQpInD8PtiVk=";
              };

              doCheck = !stdenv.isDarwin;
              checkInputs = [ pytestCheckHook ];
              pythonImportsCheck = [ "libdyson" ];

              meta = with pkgs.lib; {
                description = "Python library for dyson devices";
                homepage =
                  "https://github.com/shenxn/libdyson";
                platforms = platforms.unix;
                maintainers = with maintainers; [ mayniklas ];
              };
            };

          dyson_exporter = with pkgs.python3Packages;
            buildPythonPackage rec {
              pname = "dyson_exporter";
              version = "1.0.0";

              propagatedBuildInputs = [ prometheus-client libdyson ];
              src = self;

              doCheck = false;

              meta = with pkgs.lib; {
                description = "prometheus exporter for Dyson";
                homepage =
                  "https://github.com/MayNiklas/dyson-exporter";
                platforms = platforms.unix;
                maintainers = with maintainers; [ mayniklas ];
              };
            };

        };
        defaultPackage = packages.dyson_exporter;
      });
}
