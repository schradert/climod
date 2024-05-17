{
  description = "My CLI";
  inputs.nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
  inputs.climod.url = github:schradert/climod;
  outputs = inputs: let
    system = "<system>";
  in {
    packages.${system}.default = inputs.climod.lib.mkCLI inputs.nixpkgs.legacyPackages.${system} {
      name = "demo";
      description = "Demo CLI generated";
      action = ''
        echo Hello, world
        echo $#
        while [ $# -gt 0 ]; do
          echo "$1"
          shift
        done
      '';
      target.prelude = ''
        echo "Starting..."
      '';
      allowExtraArguments = true;
      subcommands.args.description = "Print args";
      subcommands.args.allowExtraArguments = true;
      subcommands.args.action = ''
        for line in "$@"; do
          echo $line
        done
      '';
      subcommands.eoq.description = "Eoq subcommand";
      subcommands.eoq.subcommands.greet.description = "Greets the user";
      subcommands.eoq.subcommands.greet.action = "echo Hello, $GREET_USER!";
      subcommands.eoq.subcommands.greet.flags = [
        {
          description = "User name";
          keywords    = ["-n" "--name" ];
          variable    = "GREET_USER";
        }
      ];
    };
  };
}
