.PHONY: all prepare prove solidity calldata foundry-test clean

CIRCUIT_DIR    := provekit/noir-examples/basic
CLI            := provekit/target/release/provekit-cli
TEMPLATE       := provekit/provekit/groth16/contracts/ProvekitGroth16Verifier.sol
PKP_FILE       := $(CIRCUIT_DIR)/basic.pkp
PKV_FILE       := $(CIRCUIT_DIR)/basic.pkv
PROOF_FILE     := $(CIRCUIT_DIR)/proof.np
VERIFIER_SOL   := contracts/src/Verifier.sol
CALLDATA_DIR   := artifacts/calldata
PROOF_HEX      := $(CALLDATA_DIR)/proof.hex
INPUTS_TXT     := $(CALLDATA_DIR)/inputs.txt

all: solidity

# Build the provekit-cli binary (only when sources change).
$(CLI): provekit/Cargo.toml
	cd provekit && cargo build --release --bin provekit-cli

# Step 1: Compile Noir circuit + run Groth16 trusted setup.
$(PKV_FILE): $(CLI) $(CIRCUIT_DIR)/src/main.nr $(CIRCUIT_DIR)/Nargo.toml
	cd $(CIRCUIT_DIR) && ../../target/release/provekit-cli prepare . --backend groth16

prepare: $(PKV_FILE)

# Step 2: Generate a Groth16 proof from Prover.toml inputs.
$(PROOF_FILE): $(CLI) $(PKV_FILE) $(CIRCUIT_DIR)/Prover.toml
	cd $(CIRCUIT_DIR) && ../../target/release/provekit-cli prove

prove: $(PROOF_FILE)

# Step 3: Emit a circuit-specific Solidity verifier from the VK.
$(VERIFIER_SOL): $(CLI) $(PKV_FILE) $(TEMPLATE)
	mkdir -p contracts/src
	provekit/target/release/provekit-cli export-solidity \
		--pkv $(PKV_FILE) \
		--template $(TEMPLATE) \
		--out $(VERIFIER_SOL)

solidity: $(VERIFIER_SOL)

# Step 4: Export EVM calldata (proof.hex + inputs.txt) for Foundry tests.
$(PROOF_HEX): $(CLI) $(PROOF_FILE)
	mkdir -p $(CALLDATA_DIR)
	provekit/target/release/provekit-cli export-evm-proof \
		--proof $(PROOF_FILE) \
		--out-dir $(CALLDATA_DIR)

calldata: $(PROOF_HEX)

# Step 5: Run Foundry tests against the generated verifier.
foundry-test: $(VERIFIER_SOL) $(PROOF_HEX)
	cd contracts && forge test -vvv

clean:
	rm -rf $(PKP_FILE) $(PKV_FILE) $(PROOF_FILE) \
	       contracts/src/Verifier.sol contracts/out contracts/cache \
	       $(CALLDATA_DIR)
