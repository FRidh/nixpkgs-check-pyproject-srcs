{
  description = "Check how many Python packages in Nixpkgs have a pyproject.toml";

  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, utils }: utils.lib.eachSystem ["x86_64-linux"] (system: let

    pkgs = nixpkgs.legacyPackages.${system};
    
    # Attribute set with name and src path
    srcs = with pkgs.lib; let
      canEval = value: (builtins.tryEval (deepSeq value value)).success;
      hasSrc = value: value?src;
      filterSrcs = filterAttrs (attr: value: canEval value && isDerivation value && hasSrc value);
      getSrcs = mapAttrs (attr: drv: drv.src );
    in getSrcs (filterSrcs pkgs.python3.pkgs);
  
    test = attr: src: with pkgs; stdenv.mkDerivation {
      name = "test-src-result-${attr}.json";
      inherit src;

      nativeBuildInputs = [ 
        ensureNewerSourcesForZipFilesHook
      ];

      dontBuild = true;

      installPhase = ''
        if [[ -f pyproject.toml ]]; then
          echo '{"pyproject": true}' > $out
        else
          echo '{"pyproject": false}' > $out
        fi
      '';     

    };

    tests = with pkgs.lib; builtins.toJSON (mapAttrs test srcs);

    # analysis = pkgs.writers.writePython3Bin "analysis" {

    # } ''
      

    # '';

  in {

    defaultPackage = tests;

  });
}
