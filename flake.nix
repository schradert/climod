{
  description = "Generate command line interfaces from modules";
  outputs = _: {
    templates.default.path = ./examples;
    lib.mkCLI = pkgs: _module: let
      module = pkgs.lib.evalModules {
        modules = [_module ./modules];
        specialArgs = {inherit pkgs;};
      };
      out = module.config.target.drv;
    in
      out.overrideAttrs (_: {
        passthru = {
          inherit (module) config options;
          inherit module;
        };
      });
  };
}
