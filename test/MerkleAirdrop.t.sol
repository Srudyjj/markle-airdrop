// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop public airdrop;
    BagelToken public bagelToken;

    bytes32 public constant ROOT = 0xb1e815a99ee56f7043ed94e7e2316238187a59d85c211d06f9be7c5f94424aec;
    uint256 public AMOUNT_TO_CLAIM = 2500 * 1e18; // Example claim amount for the test user
    uint256 public AMOUNT_TO_SEND; // Total tokens to fund the airdrop contract
    bytes32 public constant ProofOne = 0x9e10faf86d92c4c65f81ac54ef2a27cc0fdf6bfea6ba4b1df5955e47f187115b;
    bytes32 public constant ProofTwo = 0x8c1fd7b608678f6dfced176fa3e3086954e8aa495613efcd312768d41338ceab;
    bytes32[] public PROOF = [ProofOne, ProofTwo];

    address gasPayer;
    address user;
    uint256 userPrivateKey;

    function setUp() public {
        // 1. Deploy the ERC20 Token
        bagelToken = new BagelToken();

        // 2. Generate a Deterministic Test User
        // `makeAddrAndKey` creates a predictable address and private key.
        // This is crucial because we need to know the user's address *before*
        // generating the Merkle tree that includes them.
        (user, userPrivateKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");

        // 3. Deploy the MerkleAirdrop Contract
        // Pass the Merkle ROOT and the address of the token contract.
        airdrop = new MerkleAirdrop(ROOT, bagelToken);

        // 4. Fund the Airdrop Contract (Critical Step!)
        // The airdrop contract needs tokens to distribute.
        // Let's assume our test airdrop is for 4 users, each claiming AMOUNT_TO_CLAIM.
        AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;

        // The test contract itself is the owner of the BagelToken by default upon deployment.
        address owner = address(this); // or token.owner() if explicitly set elsewhere

        // Mint tokens to the owner (the test contract).
        bagelToken.mint(owner, AMOUNT_TO_SEND);

        // Transfer the minted tokens to the airdrop contract.
        // Note the explicit cast of `airdrop` (contract instance) to `address`.
        bagelToken.transfer(address(airdrop), AMOUNT_TO_SEND);
    }

    function testUserCanClaim() public {
        uint256 startingBalance = bagelToken.balanceOf(user);
        // 1. Get the message digest that the user needs to sign
        // This calls the getMessageHash function from the MerkleAirdrop contract
        bytes32 digest = airdrop.getMessageHash(user, AMOUNT_TO_CLAIM);

        // 2. User signs the digest using their private key
        // vm.sign is a Foundry cheatcode
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(userPrivateKey, digest);

        // 3. The gasPayer calls the claim function with the user's signature
        vm.prank(gasPayer); // Set the next msg.sender to be gasPayer
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        uint256 endingBalance = bagelToken.balanceOf(user);
        console.log("Ending Balance: ", endingBalance);
        assertEq(endingBalance, startingBalance + AMOUNT_TO_CLAIM);
    }
}
