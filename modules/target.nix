{lib, config, pkgs, ...}: {
  options.target = with lib; with types; {
    prelude = mkOption {
      type = lines;
      description = "Stuff that must be added before the argument parser";
      default = "";
    };
    code = mkOption {
      type = lines;
      description = "Code output";
    };
    drv = mkOption {
      type = types.package;
      description = "Package using the shell script version as a binary";
    };
    validators = mkOption {
      type = attrsOf str;
      description = "Parameter validators";
    };
  };
  config.target.drv = pkgs.writeShellApplication {
    inherit (config) name;
    text = config.target.code;
  };
  config.target.validators = {
    any = "true";
    fso = ''test -e "$1"'';
    file = ''test -f "$1"'';
    dir = ''test -d "$1"'';
    readable = ''test -r "$1"'';
    writable = ''test -w "$1"'';
    executable = ''test -x "$1"'';
    pipe = ''test -p "$1"'';
    socket = ''test -S "$1"'';
    not-empty = ''test -s "$1"'';
    int = ''echo $1 | grep -Eq "^-?[0-9]*$"'';
    float = ''echo $1 | grep -Eq "^-?[0-9]*.?[0-9]*$"'';
  };
}
