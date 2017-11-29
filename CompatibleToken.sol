pragma solidity ^0.4.15;

import "./ERC223.sol";

/* Implements the ERC223 Interface and adds ERC20 compatibility functions (approve, transferFrom, etc) */
contract CompatibleToken is ERC223 {

  // Token public variables
  string public name;
  string public symbol;
  uint8 public decimals;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;

  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
  event Approval(address indexed owner, address indexed spender, uint256 value);


  // Safe math
  function safeAdd(uint x, uint y) internal returns (uint z) {
    require((z = x + y) >= x);
  }
  function safeSub(uint x, uint y) internal returns (uint z) {
    require((z = x - y) <= x);
  }


  // Public functions (based on https://github.com/Dexaran/ERC223-token-standard/tree/Recommended)

  // Function that is called when a user or another contract wants to transfer funds to an address that has a non-standard fallback function
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) returns (bool success) {
      
    if(isContract(_to)) {
      require(balances[msg.sender] >= _value);
      balances[msg.sender] = safeSub(balances[msg.sender] , _value);
      balances[_to] = safeAdd(balances[_to], _value);
      ContractReceiver receiver = ContractReceiver(_to);
      receiver.call.value(0)(bytes4(sha3(_custom_fallback)), msg.sender, _value, _data);
      Transfer(msg.sender, _to, _value, _data);
      return true;
    }
    else {
      return transferToAddress(_to, _value, _data);
    }
}

  // Function that is called when a user or another contract wants to transfer funds to an address with tokenFallback function
  function transfer(address _to, uint _value, bytes _data) returns (bool success) {
      
    if(isContract(_to)) {
      return transferToContract(_to, _value, _data);
    }
    else {
      return transferToAddress(_to, _value, _data);
    }
}


  // Standard function transfer similar to ERC20 transfer with no _data.
  // Added due to backwards compatibility reasons.
  function transfer(address _to, uint _value) returns (bool success) {

    bytes memory empty;
    if(isContract(_to)) {
      return transferToContract(_to, _value, empty);
    }
    else {
      return transferToAddress(_to, _value, empty);
    }
}

//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private returns (bool is_contract) {
    uint length;
    assembly {
      //retrieve the size of the code on target address, this needs assembly
      length := extcodesize(_addr)
    }
    return (length>0);
  }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value, _data);
    return true;
  }
  
  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = safeSub(balances[msg.sender] , _value);
    balances[_to] = safeAdd(balances[_to] , _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    return true;
}


  function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
    require(balances[_from] >= _value); // Check if the sender has enough
    require(_value <= allowed[_from][msg.sender]); // Check allowance

    balances[_from] = safeSub(balances[_from] , _value); // Subtract from the sender
    balances[_to] = safeAdd(balances[_to] , _value); // Add the same to the recipient

    allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender] , _value);

    bytes memory empty;

    if (isContract(_to)) {
      ContractReceiver receiver = ContractReceiver(_to);
      receiver.tokenFallback(_from, _value, empty);
    }

    Transfer(_from, _to, _value, empty);
    return true;
  }


  function balanceOf(address _owner) constant returns(uint256 balance) {
    return balances[_owner];
  }


  function approve(address _spender, uint _value) returns(bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) constant returns(uint256) {
    return allowed[_owner][_spender];
  }
}
