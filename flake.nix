
{
  description = "an impure flake";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
  };

  outputs = inputs:
  let
    pkgs = import inputs.nixpkgs {system="x86_64-linux";};
    mkPkg = num:
      pkgs.runCommandNoCC "foo${toString num}.txt" {} ''
        sleep $(( 1 * ${toString num} ))
        echo ${toString builtins.currentTime} >> $out
      '';
  in
  {
    packages.x86_64-linux = {
      test1 = mkPkg 1;
      #test2 = mkPkg 2;
      #test3 = mkPkg 3;
    };
    defaultPackage.x86_64-linux =
      pkgs.linkFarmFromDrvs "bundle" (builtins.attrValues inputs.self.packages.x86_64-linux);
  };
}

