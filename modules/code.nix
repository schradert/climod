{lib, config, ...}: with lib; with types; {
  config = {
    target.code = let
      mkHelp = cfg: let
        subcommands = mapAttrsToList (name: cmd: "printf '\t$(bold '${name}'): ${cmd.description}\n'") cfg.subcommands;
        flags = forEach cfg.flags (flag: let
          bold = "${concatStringsSep ", " flag.keywords}, ${flag.variable}";
        in "printf '\t$(bold '${bold}') (${flag.validator}): ${flag.description}'");
      in ''
        printf '$(bold '${concatStringsSep " " cfg._subcommand}') ${cfg.description}\n'
        ${optionalString (length (attrValues cfg.subcommands) > 0) "printf '\nSubcommands\n'"}
        ${concatStringsSep "\n" subcommands}
        ${optionalString (length cfg.flags > 0) "printf '\nFlags\n'"}
        ${concatStringsSep "\n" flags}
        exit 0
      '';
      mkCommandTree = cfg: let
        mkSubcommandHandler = name: _cmd: let
          cmd = _cmd // {
            flags = cfg.flags ++ _cmd.flags;
            _subcommand = cfg._subcommand ++ [_cmd.name];
          };
        in ''
          ${name})
            shift
            ${mkCommandTree cmd}
            exit 0
            ;;
        '';
        mkFlagHandler = flag: let
          isBool = flag.validator == "bool";
          isHelp = elem "-h" flag.keywords;
          validateExprError = "echo \"flag '$flagkey' (${flag.variable}) doesn't pass the validation as a ${flag.validator}\"";
        in
          if isHelp then mkHelp cfg else ''
            ${concatStringsSep " | " flag.keywords})
              ${optionalString isBool "export ${flag.variable}=1; shift; continue"}
              if [[ $# -eq 1 ]]; then
                error "the flag '$flagkey' expects a value of type ${flag.validator} but found end of parameters"
              fi
              ${optionalString (!isBool) "validate_${flag.validator} \"$2\" || ${validateExprError}"}
              ${flag.variable}="$2"
              shift 2
              break
              ;;
          '';
        requiredFlags = pipe cfg.flags [
          (filter (getAttr "required"))
          (map (flag: "echo \"\$${flag.variable}\" >/dev/null"))
        ];
      in ''
        if [ $# -gt 0 ]; then
          case "$1" in
            ${concatStringsSep "\n" (mapAttrsToList mkSubcommandHandler cfg.subcommands)}
          esac
        fi
        ARGS=()
        while [[ ! $# -eq 0 ]]; do
          local flagkey="$1"
          case "$flagkey" in
              ${concatStringsSep "\n" (map mkFlagHandler cfg.flags)}
              *)
                ${if cfg.allowExtraArguments then "ARGS+=(\"$1\"); shift" else "error \"invalid keyword argument near '$flagkey'\""}
                ;;
          esac
        done
        ${concatStringsSep "\n" requiredFlags}
        function payload {
          ${cfg.action}
        }
        payload "''${ARGS[@]}"
        exit 0
      '';
      mkValidatorHandler = name: code: ''
        function validate_${name} {
          ${code}
        }
      '';
    in ''
        #!/usr/bin/env bash
        set -euo pipefail
        function bold {
          if which tput >/dev/null 2>/dev/null; then
            printf "$(tput bold)$*$(tput sgr0)"
          else
            printf "$*"
          fi
        }
        function error {
          echo "$(bold "error"): $@" >&2
          exit 1
        }
        ${concatStringsSep "\n" (mapAttrsToList mkValidatorHandler config.target.validators)}

        ${config.target.prelude}

        function _main() {
          ${mkCommandTree (config // {
            _subcommand = [ config.name ];
          })}
        }
        _main "$@"
    '';
  };
}
