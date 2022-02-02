// @format
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) Tim Daubenschütz.
pragma solidity ^0.8.6;

import {StateTree} from "indexed-sparse-merkle-tree/StateTree.sol";

function hash(Leaf memory l) pure returns (bytes32) {
    if (l.price == 0) {
        return 0;
    }
    return keccak256(abi.encode(
        l.text,
        l.owner,
        l.price,
        l.blockNumber
    ));
}

struct Leaf {
    string text;
    address owner;
    uint256 price;
    uint256 blockNumber;
}

struct Proof {
    bytes32[] list;
    uint8 bits;
}

struct Transition {
    uint256 postId;
    Leaf prev;
    Proof proof;
}

contract Guestbook {
    bytes32 public root;

    constructor() {
        root = StateTree.empty();
    }

    function enter(Transition memory t, string memory text) external payable {
        Leaf memory next = Leaf(text, msg.sender, msg.value, block.number);
        bool valid = StateTree.validate(
            t.proof.list,
            t.proof.bits,
            t.postId,
            hash(t.prev),
            root
        );
        require(valid, "invalid proof");
        root = StateTree.compute(
            t.proof.list,
            t.proof.bits,
            t.postId,
            hash(next)
        );


    }
}
