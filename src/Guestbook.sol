// @format
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) Tim Daubenschütz.
pragma solidity ^0.8.6;

import "indexed-sparse-merkle-tree/StateTree.sol";

function leaf(
    string calldata _text,
    uint256 _price
) pure returns (bytes32) {
    if (_price == 0) {
        return 0;
    }
    return keccak256(abi.encode(_text, _price));
}


struct Transition {
    uint256 postId;
    string oldEntry;
    string newEntry;
    uint256 oldPrice;
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

    function withdraw() public {
        require(msg.sender == owner, "only owner");
        payable(msg.sender).transfer(address(this).balance);
    }

    function enter(
        Transition calldata _transition,
        bytes32[] calldata _proofs,
        uint8 _bits
    ) public payable {
        require(msg.value > _transition.oldPrice, "price too low");
        root = StateTree.write(
            _proofs,
            _bits,
            _transition.postId,
            leaf(_transition.newEntry, msg.value),
            leaf(_transition.oldEntry, _transition.oldPrice),
            root
        );
        emit Entry(
            msg.sender,
            _transition.postId,
            _transition.newEntry,
            msg.value
        );
    }
}
