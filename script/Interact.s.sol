// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol"; // Relative path to your MerkleAirdrop contract

contract ClaimAirdrop is Script {
    // Define parameters for the claim function
    address CLAIMING_ADDRESS = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B; // Example address from input.json
    uint256 CLAIMING_AMOUNT = 25 * 1e18; // Example: 25 tokens with 18 decimals

    // Merkle Proof for CLAIMING_ADDRESS and CLAIMING_AMOUNT
    // These values are copied from the output.json generated by MakeMerkle.s.sol
    // for the specific CLAIMING_ADDRESS
    bytes32 PROOF_ONE = 0x88a7750cb9fae3dc8e9506155674c532538ead1af8912c0681d37bf014f16a42; // Example proof element
    bytes32 PROOF_TWO = 0x8c1fd7b608678f6dfced176fa3e3086954e8aa495613efcd312768d41338ceab; // Example proof element
    bytes32[] proof = [PROOF_ONE, PROOF_TWO]; // Assuming a proof length of 2 for this example
    bytes private SIGNATURE =
        hex"3b16382d950929b500b8c07e1d137f98cc8729df19332cafa20a04394ab918706c6db0c1ad627394aa852e08919f7cea94cd1cec3691dd38d498bea091ed43501b";

    error ClaimAirdropScript__InvalidSignatureLength();

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployed);
    }

    function claimAirdrop(address airdropAddress) internal {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirdrop airdrop = MerkleAirdrop(airdropAddress);
        // Call the claim function on the MerkleAirdrop contract
        airdrop.claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, proof, v, r, s);
        vm.stopBroadcast();
    }

    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert ClaimAirdropScript__InvalidSignatureLength();
        }
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
