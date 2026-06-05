.PHONY: all keys solidity foundry-test clean

PROVEKIT_CLI := go run ./provekit/recursive-verifier/cmd/cli
GNARK_PARAMS := provekit/gnark_params.json
GNARK_R1CS   := provekit/gnark_r1cs.json
KEYS_DIR     := artifacts/keys
VK_FILE      := $(KEYS_DIR)/vk.bin
PK_FILE      := $(KEYS_DIR)/pk.bin
VERIFIER_SOL := contracts/src/Verifier.sol

all: solidity

# Step 1: Run gnark recursive verifier to generate PK/VK.
# Uses the pre-existing gnark_params.json + gnark_r1cs.json from the provekit submodule.
# The CLI saves keys with timestamped filenames under --saveKeys; we rename to canonical paths.
$(VK_FILE): $(GNARK_PARAMS) $(GNARK_R1CS)
	rm -rf $(KEYS_DIR)
	mkdir -p $(KEYS_DIR)
	cd provekit/recursive-verifier && go run ./cmd/cli \
		--config ../../$(GNARK_PARAMS) \
		--r1cs ../../$(GNARK_R1CS) \
		--saveKeys ../../$(KEYS_DIR)
	mv $(KEYS_DIR)/pk_*.bin $(PK_FILE)
	mv $(KEYS_DIR)/vk_*.bin $(VK_FILE)

keys: $(VK_FILE)

# Step 2: Export Solidity verifier contract from the VK.
$(VERIFIER_SOL): $(VK_FILE)
	mkdir -p contracts/src
	go run ./cmd/export --vk $(VK_FILE) --out $(VERIFIER_SOL)

solidity: $(VERIFIER_SOL)

# Step 3: Run Foundry tests against the exported Solidity verifier.
foundry-test: $(VERIFIER_SOL)
	cd contracts && forge test -vvv

clean:
	rm -rf artifacts/keys contracts/src/Verifier.sol contracts/out contracts/cache
