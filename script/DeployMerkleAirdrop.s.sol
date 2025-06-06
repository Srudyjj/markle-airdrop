// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {

    bytes32 public constant ROOT = 0xb1e815a99ee56f7043ed94e7e2316238187a59d85c211d06f9be7c5f94424aec;
    uint256 public constant TRANSFER_AMOUNT = 4 * 2500 * 1e18;


    function deployMarkleAirdrop() internal returns (MerkleAirdrop, BagelToken) {
        vm.startBroadcast();

        BagelToken bagelToken = new BagelToken();
        MerkleAirdrop merkleAirdrop = new MerkleAirdrop(ROOT, IERC20(address(bagelToken)));

        console.log("BagelToken deployed at:", address(bagelToken));
        console.log("MerkleAirdrop deployed at:", address(merkleAirdrop));

        // Mint tokens to the Merkle Airdrop contract
        bagelToken.mint(bagelToken.owner(), TRANSFER_AMOUNT);
        // Transfer tokens to the Merkle Airdrop contract
        bagelToken.transfer(address(merkleAirdrop), TRANSFER_AMOUNT);
        console.log("BagelToken balance of MerkleAirdrop:", bagelToken.balanceOf(address(merkleAirdrop)));

        vm.stopBroadcast();
        return (merkleAirdrop, bagelToken);
    }


    function run() external returns (MerkleAirdrop, BagelToken) {
        return deployMarkleAirdrop();
    }

}
