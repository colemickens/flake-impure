
{
  description = "an impure flake";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
  };

  outputs = inputs:
  let
    nameValuePair = name: value: { inherit name value; };
    genAttrs = names: f: builtins.listToAttrs (map (n: nameValuePair n (f n)) names);
    supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = genAttrs supportedSystems;

    pkgsFor = pkgs: sys: import pkgs {
      system = sys;
      config = { allowUnfree = true; };
    };
    pkgs_ = genAttrs (builtins.attrNames inputs) (inp: genAttrs supportedSystems (sys: pkgsFor inputs."${inp}" sys));

    mkPkg = sys: num:
      pkgs_.nixpkgs."${sys}".runCommandNoCC "foo${toString num}.txt" {} ''
        sleep $(( 1 * ${toString num} ))
        echo ${toString builtins.currentTime} >> $out
      '';
  in
  {
    packages = forAllSystems (sys:
      { test1 = mkPkg sys 1;}
    );

    defaultPackage = forAllSystems (sys:
      pkgs_.nixpkgs."${sys}".linkFarmFromDrvs "bundle"
        (builtins.attrValues inputs.self.packages."${sys}")
    );
  };
}

