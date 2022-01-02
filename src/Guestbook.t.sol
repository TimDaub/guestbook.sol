// @format
pragma solidity ^0.8.6;
import "ds-test/test.sol";

import "./Guestbook.sol";
import "indexed-sparse-merkle-tree/StateTree.sol";

contract GuestbookTest is DSTest {
    Guestbook g;

    receive() external payable { }

    function genMapVal(uint8 bufLength, uint8 index) public returns (uint8) {
        uint8 bytePos = (bufLength - 1) - (index / 8);
        return bytePos + 1 << (index % 8);
    }

    function setUp() public {
        g = new Guestbook(address(this));
    }

    function testEnterFirst() public {
       	bytes32[] memory proofs = new bytes32[](0);
		g.enter{value: 1}("Hello", proofs, 0, 0);
    }

    function testEnterFirstAndSecond() public {
       	bytes32[] memory proofs = new bytes32[](0);
        string memory firstString = "hello world";
		g.enter{value: 1}(firstString, proofs, 0, 0);

       	bytes32[] memory proofs2 = new bytes32[](1);
        proofs2[0] = keccak256(abi.encode(firstString));
		g.enter{value: 1}("World", proofs2, 1, StateTree.bitmap(0));
    }

    function testWithdrawing() public {
       	bytes32[] memory proofs = new bytes32[](0);
        string memory firstString = "hello world";
		g.enter{value: 1 ether}(firstString, proofs, 0, 0);

        uint256 balance = address(g).balance;
        assertEq(balance, 1 ether);
        g.withdraw();
        uint256 balance2 = address(g).balance;
        assertEq(balance2, 0 ether);
    }
}
