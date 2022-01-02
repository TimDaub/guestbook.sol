// @format
pragma solidity ^0.8.6;

import "indexed-sparse-merkle-tree/StateTree.sol";

contract Guestbook {
    bytes32 public root;
    address owner;
    uint256 size;
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
        require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
    }

    function enter(
        string calldata _entry,
        bytes32[] calldata _proofs,
        uint256 _index,
        uint8 _bits
    ) public payable {
        require(msg.value > 0);
        root = StateTree.write(
            _proofs,
            _bits,
            _index,
            keccak256(abi.encode(_entry)),
            0,
            root
        );
        emit Entry(msg.sender, _index, _entry, msg.value);
    }
}
