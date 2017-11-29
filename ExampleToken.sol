pragma solidity ^0.4.15;

import "./CompatibleToken.sol";

/**
 * Start here with custom logic implementation.
 */
contract ExampleCoin is CompatibleToken {
  function ExampleCoin() {
    name = "Example";
    symbol = "EXC";
    decimals = 18;
    totalSupply = 10000000 * 10 ** decimals;
    balances[msg.sender] = totalSupply;
  }
}