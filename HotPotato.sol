pragma solidity ^0.5.0;

//import "./Receiver_Interface.sol";
 contract ContractReceiver {
     
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    
    
}

//import "./ERC223_Interface.sol";
contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  
  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes memory data) public returns (bool ok);
  function transfer(address to, uint value, bytes memory data, string memory custom_fallback) public returns (bool ok);
  
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

 /**
 * ERC223 token by Dexaran
 *
 * https://github.com/Dexaran/ERC223-token-standard
 */
 
 
 /* https://github.com/LykkeCity/EthereumApiDotNetCore/blob/master/src/ContractBuilder/contracts/token/SafeMath.sol */
contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) revert();
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x < y) revert();
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) revert();
        return x * y;
    }
}
 
contract HotPotatoToken is ERC223, SafeMath {

  mapping(address => uint) balances;
  
  string public name = "Hot Potato Token v0";
  string public symbol = "HPT";
  uint8 public decimals = 18;
  uint256 public totalSupply = 0;
  
  constructor() public {
      //balances[msg.sender]=totalSupply;
      
      burnTime=block.timestamp+60*60;
      burnTarget=msg.sender;
  }
  
  
  
  // Primary Hot Potato Code
  uint burnTime;
  uint hptSupply;
  address burnTarget;
  
  address[] hodlers; // array of all hodlers
  mapping (address=>uint) hodlIndex; // where the hodlers at?
  
  // TODO allow burner to move potato
  function detonatePotato() public returns (bool){

      // is it time to burn someone?
      if(block.timestamp < burnTime)return false;
      
      // ooo too bad
      hptSupply=safeSub(hptSupply,balances[burnTarget]);
      balances[burnTarget]=0;
      
      delHodler(hodlIndex[burnTarget]);

      burnTime=block.timestamp+60*60;
  }
  
  function movePotato() public returns (bool){
      // only the target should be able to move potato
      if(msg.sender!=burnTarget) return false;
      
      burnTarget = hodlers[(hodlIndex[burnTarget]+1)%hodlers.length];
      return true;
  }
  
  function addHodler(address hodler) private returns (bool){
      if(hodlIndex[hodler]!=0)return false; // make sure it's not there already
      hodlIndex[hodler] = hodlers.length; //hodler should be last line 
      hodlers.push(hodler); // add hodler to hodlers
      return true;
  }
  
  function delHodler(uint index) private returns (bool){
      if(index > hodlers.length)return false;
      hodlIndex[hodlers[index]]=0; // delete from mapping
      delete hodlers[index]; // delete from array
      hodlers[index]=hodlers[hodlers.length-1]; // move last element to open slot
      delete hodlers[hodlers.length-1]; // trim entry from the sender\
      hodlers.length=hodlers.length-1;
      hodlIndex[hodlers[index]]=index; // reindex the moved hodler
      return true;
  }
  
  function buyHPT() public payable returns (bool){
      
      uint exchange=1000;
      if(address(this).balance==0 || hptSupply==0)exchange = 1000;
      else exchange=hptSupply/(address(this).balance-msg.value);
      
      balances[msg.sender]=safeAdd(balances[msg.sender],safeMul(msg.value,exchange));
      hptSupply=safeAdd(hptSupply,safeMul(msg.value,exchange)); // increase the supply
      addHodler(msg.sender); // just in case this this the first time
      return true;
  }
  
  function sellHPT() public returns (bool){
      
      if(balances[msg.sender]==0)return false; // nice try..
      
      hptSupply=safeSub(hptSupply,balances[msg.sender]);      
      msg.sender.transfer(balances[msg.sender]/getExchange());
      balances[msg.sender]=0;

      delHodler(hodlIndex[msg.sender]);

      return true;
  }
  
  function getExchange() public returns (uint)
  {
     if(address(this).balance==0 || hptSupply==0)return 1000;
      
     return hptSupply/address(this).balance;
  }

  function getStats() public returns(uint supply, uint totalBalance, uint balance, uint exchange,uint numPlayers,uint time, address target)
  {
      return (hptSupply, address(this).balance,balances[msg.sender], getExchange(), hodlers.length, burnTime, burnTarget);
  }
  
  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes memory _data, string memory _custom_fallback) public returns (bool success) {
    return false;
    if(isContract(_to)) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        //assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}
  

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes memory _data) public returns (bool success) {
    return false;
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}
  
  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) public returns (bool success) {
    return false;
    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}

  //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private view returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
      }
      return (length>0);
    }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes memory _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }
  
  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes memory _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    ContractReceiver receiver = ContractReceiver(_to);
    //receiver.tokenFallback(msg.sender, _value, _data);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
}


  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
}
