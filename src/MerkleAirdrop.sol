// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    // Purpose:
    // 1. Manage a list of addresses and corresponding token amounts eligible for the airdrop.
    // 2. Provide a mechanism for eligible users to claim their allocated tokens.

    address[] public claimers;

    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address claimer => bool claimed) private s_hasClaimed;

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    error MerkleAirdrop_InvalidProof();
    error MerkleAirdrop_InvalidSignature();
    error MerkleAirdrop_AlreadyClaimed();

    event Claim(address indexed account, uint256 amount);

    constructor(bytes32 _merkleRoot, IERC20 _airdropToken) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = _merkleRoot;
        i_airdropToken = _airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop_AlreadyClaimed();
        }
        //check the signature
        // Construct the digest the user should have signed
        bytes32 digest = getMessageHash(account, amount);
        // Verify the signature
        if (!_isValidSignature(account, digest, v, r, s)) {
            revert MerkleAirdrop_InvalidSignature();
        }
        // Calculate the leaf node hash
        // This implementation double-hashes the abi.encoded data.
        // Consistency between off-chain leaf generation and on-chain verification is paramount.
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

        // Inside the claim function, after calculating 'leaf':
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop_InvalidProof();
        }
        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    // verify whether the recovered signer is the expected signer/the account to airdrop tokens for
    function _isValidSignature(address signer, bytes32 digest, uint8 _v, bytes32 _r, bytes32 _s)
        internal
        pure
        returns (bool)
    {
        // could also use SignatureChecker.isValidSignatureNow(signer, digest, signature)
        (
            address actualSigner,
            /*ECDSA.RecoverError recoverError*/
            ,
            /*bytes32 signatureLength*/
        ) = ECDSA.tryRecover(digest, _v, _r, _s);
        return (actualSigner == signer);
    }
    // function _isValidSignature(address signer, bytes32 digest, uint8 _v, uint32 _r, uint32 _s)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     bytes memory signature = abi.encode(_v, _r, _s);
    //     return SignatureChecker.isValidSignatureNow(signer, digest, signature);
    // }

    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}
