
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
      pkgs_.nixpkgs."${sys}".runCommandNoCC "test${toString num}.txt" {} ''
        echo ${toString builtins.currentTime} >> $out
      '';
  in
  {
    packages = forAllSystems (sys:
      {
        test1 = mkPkg sys 1;
        test2 = mkPkg sys 2;
        test3 = mkPkg sys 3;
      }
    );

    defaultPackage = forAllSystems (sys:
      pkgs_.nixpkgs."${sys}".linkFarmFromDrvs "bundle"
        (builtins.attrValues inputs.self.packages."${sys}")
    );
  };
}

