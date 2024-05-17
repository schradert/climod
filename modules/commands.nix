{lib, ...}:
with lib;
with types;
let
  flag = submodule {
    options = {
      keywords = mkOption {
        type = nonEmptyListOf (strMatching "-[a-zA-Z0-9]|-(-[a-z0-9]*)");
        default = [];
        description = "Which keywords refer to this flag";
      };
      description = mkOption {
        type = str;
        default = "";
        description = "Description of the flag value";
      };
      validator = mkOption {
        type = str;
        default = "any";
        description = "Command to run passing the input to validate the flag value";
      };
      variable = mkOption {
        type = strMatching "[A-Z][A-Z_]*";
        description = "Variable to store the result";
      };
      required = mkOption {
        type = bool;
        description = "Is the value required?";
        default = false;
      };
    };
  };
  command = {
    name = mkOption {
      type = strMatching "[a-zA-Z0-9_][a-zA-Z0-9_\\-]*";
      default = "example";
      description = "Name of the command shown on --help";
    };
    description = mkOption {
      type = str;
      default = "Example cli script generated with nix";
      description = "Command description";
    };
    flags = mkOption {
      type = listOf flag;
      default = [];
      description = "Command flags";
    };
    subcommands = mkOption {
      type = attrsOf (submodule ({name, ...}: {
        options = command;
        config = {
          inherit name;
          flags = [help];
        };
      }));
      default = {};
      description = "Subcommands has all the attributes of commands, even subcommands...";
    };
    allowExtraArguments = mkOption {
      type = bool;
      default = false;
      description = "Allow the command to receive unmatched arguments";
    };
    action = mkOption {
      type = str;
      default = "exit 0";
      description = "Code unique to this endpoint";
    };
  };
  help = {
    keywords = ["-h" "--help"];
    description = "Show this help message";
    variable = "HELP";
  };
in {
  options = command;
  config.flags = [help];
}
