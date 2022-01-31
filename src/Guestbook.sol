// @format
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) Tim Daubenschütz.
pragma solidity ^0.8.6;

import {StateTree} from "indexed-sparse-merkle-tree/StateTree.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

function leaf(
    string calldata _text,
    address _owner,
    uint256 _price,
    uint256 _blockNumber
) pure returns (bytes32) {
    if (_price == 0) {
        return 0;
    }
    return keccak256(abi.encode(_text, _owner, _price, _blockNumber));
}

uint256 constant BLOCK_TAX_NUMERATOR = 1;
uint256 constant BLOCK_TAX_DENOMINATOR = 100;

function tax(
    uint256 startBlock,
    uint256 endBlock,
    uint256 price
) pure returns (uint256) {
    uint256 diff = endBlock - startBlock;
    uint256 scaledDenominator = BLOCK_TAX_DENOMINATOR * FixedPointMathLib.WAD;
    return FixedPointMathLib.fdiv(
        price * diff * BLOCK_TAX_NUMERATOR,
        scaledDenominator,
        FixedPointMathLib.WAD
    );
}


struct Transition {
    uint256 postId;
    string oldEntry;
    string newEntry;
    uint256 oldPrice;
    address oldOwner;
    uint256 blockNumber;
}

contract Guestbook {
    bytes32 public root;
    address owner;
    event Entry(
        address indexed _from,
        uint256 indexed _postId,
        string _entry,
        uint256 _amount
    );

    constructor(address _owner) {
        root = StateTree.empty();
        owner = _owner;
    }

    function withdraw() external {
        require(msg.sender == owner, "only owner");
        payable(msg.sender).transfer(address(this).balance);
    }

    function enter(
        Transition calldata _transition,
        bytes32[] calldata _proofs,
        uint8 _bits
    ) external payable {
        require(msg.value > 0, "need more than zero");
        require(msg.value >= _transition.oldPrice, "price too low");
        root = StateTree.write(
            _proofs,
            _bits,
            _transition.postId,
            leaf(_transition.newEntry, msg.sender, msg.value, block.number),
            leaf(_transition.oldEntry, _transition.oldOwner, _transition.oldPrice, _transition.blockNumber),
            root
        );

        uint256 taxes = tax(_transition.blockNumber, block.number, _transition.oldPrice);
        uint256 payout = _transition.oldPrice - taxes;
        if (payout > 0) {
            payable(_transition.oldOwner).transfer(payout);
        }

        emit Entry(
            msg.sender,
            _transition.postId,
            _transition.newEntry,
            msg.value
        );
    }
}
