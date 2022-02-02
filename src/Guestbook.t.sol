// @format
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) Tim Daubenschütz.
pragma solidity ^0.8.6;
import "ds-test/test.sol";

import { Guestbook, Transition, Proof, Leaf, hash } from "./Guestbook.sol";
import { StateTree } from "indexed-sparse-merkle-tree/StateTree.sol";

abstract contract Hevm {
    function roll(uint x) public virtual;
}

contract GuestbookTest is DSTest {
    Guestbook g;
	Hevm hevm;

    receive() external payable { }

    function setUp() public {
        g = new Guestbook();
		hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    }

    function testEnterFirst() public {
        Proof memory p = Proof(new bytes32[](0), 0);
        Leaf memory l = Leaf("", address(0), 0, 0);
        uint256 postId = 0;
        Transition memory t = Transition(postId, l, p);
		g.enter{value: 1}(t, "hello world");
    }

    function failEnteringWithNoValue() public {
        Proof memory p = Proof(new bytes32[](0), 0);
        Leaf memory l = Leaf("", address(0), 0, 0);
        uint256 postId = 0;
        Transition memory t = Transition(postId, l, p);
		g.enter(t, "hello world");
    }

    function testEnterFirstAndSecond() public {
        Proof memory p1 = Proof(new bytes32[](0), 0);
        Leaf memory l1 = Leaf("", address(0), 0, 0);
        uint256 postId1 = 0;
        Transition memory t1 = Transition(postId1, l1, p1);
        string memory text1 = "hello world";
        uint256 blockNumber = block.number;
		g.enter{value: 1}(t1, text1);

        Proof memory p2 = Proof(new bytes32[](1), StateTree.bitmap(0));
        Leaf memory nextL1 = Leaf(text1, address(this), 1, blockNumber);
        p2.list[0] = hash(nextL1);
        Leaf memory l2 = Leaf("", address(0), 0, 0);
        uint256 postId2 = 1;
        Transition memory t2 = Transition(postId2, l2, p2);
        string memory text2 = "second entry";

        g.enter{value: 1}(t2, text2);
    }

    function testOverbiddingPost() public {
        uint256 blockNumber = block.number;
        Proof memory p1 = Proof(new bytes32[](0), 0);
        Leaf memory l1 = Leaf("", address(0), 0, 0);
        uint256 postId1 = 0;
        Transition memory t1 = Transition(postId1, l1, p1);
        string memory text1 = "hello world";
		g.enter{value: 1}(t1, text1);

        Proof memory p2 = Proof(new bytes32[](0), 0);
        Leaf memory l2 = Leaf(text1, address(this), 1, blockNumber);
        uint256 postId2 = 0;
        Transition memory t2 = Transition(postId2, l2, p2);
        string memory text2 = "second entry";

        g.enter{value: 2}(t2, text2);
    }

    //function testSimulatingTaxation() public {
    //   	bytes32[] memory proofs = new bytes32[](0);
    //    Transition memory t = Transition(0, "", "hello", 0, address(this), 0);
	//	hevm.roll(0);
    //    uint256 blockNumber = block.number;
	//	g.enter{value: 1 ether}(t, proofs, 0);

    //    Transition memory t2 = Transition(0, t.newEntry, "world", 1 ether, address(this), blockNumber);
    //   	bytes32[] memory proofs2 = new bytes32[](0);
	//	hevm.roll(50);
    //    g.enter{value: 2 ether}(t2, proofs2, 0);
	//	assertEq(address(g).balance, 2.5 ether);
    //}
}
