//SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract SIGN {
    function hashMessage(bytes32  message) public view returns (bytes32 messageHash) {
    messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
    return messageHash;
  }

  function verifyEcrecover(bytes32  messageHash, uint8 v, bytes32 r, bytes32 s) public view returns (address recoveredAddress) {
    bytes32 hash = hashMessage(messageHash);
    return  ecrecover(hash, v, r, s);
  }
}