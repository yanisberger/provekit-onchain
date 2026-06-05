// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Verifier.sol";

contract VerifierTest is Test {
    Verifier verifier;

    function setUp() public {
        verifier = new Verifier();
    }

    // Smoke test: deploy succeeds and the verifier contract exists.
    function test_deploys() public view {
        assertTrue(address(verifier) != address(0));
    }

    // TODO: add a test that calls verifier.verifyProof(proof, input) with
    // real calldata from artifacts/calldata.json once proof export is wired up.
    // The gnark-exported Solidity verifier exposes:
    //   function verifyProof(uint[8] memory proof, uint[N] memory input) public view returns (bool)
}
