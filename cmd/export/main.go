package main

import (
	"fmt"
	"log"
	"os"

	"github.com/consensys/gnark-crypto/ecc"
	"github.com/consensys/gnark/backend/groth16"
)

func main() {
	if len(os.Args) < 3 {
		fmt.Fprintf(os.Stderr, "Usage: export --vk <vk.bin> --out <Verifier.sol>\n")
		os.Exit(1)
	}

	var vkPath, outPath string
	for i := 1; i < len(os.Args)-1; i++ {
		switch os.Args[i] {
		case "--vk":
			vkPath = os.Args[i+1]
		case "--out":
			outPath = os.Args[i+1]
		}
	}
	if vkPath == "" || outPath == "" {
		log.Fatal("--vk and --out are required")
	}

	vkFile, err := os.Open(vkPath)
	if err != nil {
		log.Fatalf("opening vk: %v", err)
	}
	defer vkFile.Close()

	vk := groth16.NewVerifyingKey(ecc.BN254)
	if _, err := vk.ReadFrom(vkFile); err != nil {
		log.Fatalf("reading vk: %v", err)
	}

	solFile, err := os.Create(outPath)
	if err != nil {
		log.Fatalf("creating output file: %v", err)
	}
	defer solFile.Close()

	if err := vk.ExportSolidity(solFile); err != nil {
		log.Fatalf("exporting solidity: %v", err)
	}

	log.Printf("Solidity verifier written to %s", outPath)
}
