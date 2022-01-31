// @format
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) Tim Daubenschütz.
pragma solidity ^0.8.6;
import "ds-test/test.sol";

import { Guestbook, Transition, tax, leaf } from "./Guestbook.sol";
import { StateTree } from "indexed-sparse-merkle-tree/StateTree.sol";

abstract contract Hevm {
    function roll(uint x) public virtual;
}

contract GuestbookTest is DSTest {
    Guestbook g;
	Hevm hevm;

    receive() external payable { }

    function setUp() public {
        g = new Guestbook(address(this));
		hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    }

    function testBlockTax() public {
        assertEq(tax(0, 50, 1 ether), 0.5 ether);
        assertEq(tax(0, 1, 1 ether), 0.01 ether);
    }

    function testEnterFirst() public {
       	bytes32[] memory proofs = new bytes32[](0);
        Transition memory t = Transition(0, "", "hello world", 0, address(this), 0);
		g.enter{value: 1}(t, proofs, 0);
    }

    function failEnteringWithNoValue() public {
       	bytes32[] memory proofs = new bytes32[](0);
        Transition memory t = Transition(0, "", "hello world", 0, address(this), 0);
		g.enter(t, proofs, 0);
    }

    function testEnterFirstAndSecond() public {
       	bytes32[] memory proofs = new bytes32[](0);
        Transition memory t = Transition(0, "", "hello world", 0, address(this), 0);
        uint256 blockNumber = block.number;
		g.enter{value: 1}(t, proofs, 0);

        Transition memory t2 = Transition(1, "", "World", 0, address(this), blockNumber);
       	bytes32[] memory proofs2 = new bytes32[](1);
        proofs2[0] = keccak256(abi.encode(t.newEntry, address(this), 1, 0));
        g.enter{value: 1}(t2, proofs2, StateTree.bitmap(0));
    }

    function testOverbiddingPost() public {
       	bytes32[] memory proofs = new bytes32[](0);
        Transition memory t = Transition(0, "", "hello", 0, address(this), 0);
        uint256 blockNumber = block.number;
		g.enter{value: 1}(t, proofs, 0);

        Transition memory t2 = Transition(0, t.newEntry, "world", 1, address(this), blockNumber);
       	bytes32[] memory proofs2 = new bytes32[](0);
        g.enter{value: 2}(t2, proofs2, 0);
    }

    function testSimulatingTaxation() public {
       	bytes32[] memory proofs = new bytes32[](0);
        Transition memory t = Transition(0, "", "hello", 0, address(this), 0);
		hevm.roll(0);
        uint256 blockNumber = block.number;
		g.enter{value: 1 ether}(t, proofs, 0);

        Transition memory t2 = Transition(0, t.newEntry, "world", 1 ether, address(this), blockNumber);
       	bytes32[] memory proofs2 = new bytes32[](0);
		hevm.roll(50);
        g.enter{value: 2 ether}(t2, proofs2, 0);
		assertEq(address(g).balance, 2.5 ether);
    }

    function testWithdrawing() public {
       	bytes32[] memory proofs = new bytes32[](0);
        Transition memory t = Transition(0, "", "hello world", 0, address(this), 0);
		g.enter{value: 1 ether}(t, proofs, 0);

        uint256 balance = address(g).balance;
        assertEq(balance, 1 ether);
        g.withdraw();
        uint256 balance2 = address(g).balance;
        assertEq(balance2, 0 ether);
    }
}
