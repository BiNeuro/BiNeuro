pragma solidity ^0.4.19;

library SafeMath { //standart library for uint
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0){
        return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function pow(uint256 a, uint256 b) internal pure returns (uint256){ //power function
    if (b == 0){
      return 1;
    }
    uint256 c = a**b;
    assert (c >= a);
    return c;
  }
}

//standart contract to identify owner
contract Ownable {

  address public owner;

  address public newOwner;

  address public techSupport;

  address public newTechSupport;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyTechSupport() {
    require(msg.sender == techSupport);
    _;
  }

  function Ownable() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      owner = newOwner;
    }
  }

  function transferTechSupport (address _newSupport) public{
    require (msg.sender == owner || msg.sender == techSupport);
    newTechSupport = _newSupport;
  }

  function acceptSupport() public{
    if(msg.sender == newTechSupport){
      techSupport = newTechSupport;
    }
  }

}

//Abstract Token contract
contract BineuroToken{
  function setCrowdsaleContract (address) public{}
  function sendCrowdsaleTokens(address, uint256)  public {}
  function burnTokens(address, address, uint) public {}
  function getOwner()public view returns(address) {}
}

//Crowdsale contract
contract Crowdsale is Ownable{

  using SafeMath for uint;

  uint decimals = 3;
  // Token contract address
  BineuroToken public token;

  // Constructor
  function Crowdsale(address _tokenAddress) public{
    token = BineuroToken(_tokenAddress);
    techSupport = msg.sender;

    // test parameter
    // techSupport = 0x8C0F5211A006bB28D4c694dC76632901664230f9;

    token.setCrowdsaleContract(this);
    owner = token.getOwner();
  }

  // for Test
  // CHANGE IT before deploy into main network
  
  address etherDistribution1 = 0xBBBBaAeDaa53EACF57213b95cc023f668eDbA361;
  address etherDistribution2 = 0xaeB0920be125eB72e071B1357A5c95B52D8afc65;

  address teamAddress = 0x8C0F5211A006bB28D4c694dC76632901664230f9;
  address bountyAddress = 0x112f94de76c8df26786671bee2ccc75bd9613a1b;

  // CHANGE ABOVE before deploy into main network
  // above is for Test

  //Crowdsale variables
  uint public tokensSold = 0;
  uint public ethCollected = 0;

  // Buy constants
  uint minDeposit = (uint)(50).mul((uint)(10).pow(decimals));

  uint tokenPrice = 0.001 ether;

  // Ico constants
  uint public icoStart = 0; //02/14/2018 1518602400
  uint public icoFinish = 1521151199; //03/15/2018

  //Owner can change end date
  function changeIcoFinish (uint _newDate) public onlyOwner {
    icoFinish = _newDate;
  }
  
  //check is now ICO
  function isIco(uint _time) public view returns (bool){
    if((icoStart <= _time) && (_time < icoFinish)){
      return true;
    }
    return false;
  }

  function timeBasedBonus(uint _time) public view returns(uint res) {
    res = 20;
    uint timeBuffer = icoStart;
    for (uint i = 0; i<10; i++){
      if(_time <= timeBuffer + 7 days){
        return res;
      }else{
        res = res - 2;
        timeBuffer = timeBuffer + 7 days;
      }
      if (res == 0){
        return (0);
      }
    }
    return res;
  }
  
  function volumeBasedBonus(uint _value)public pure returns(uint res) {
    if(_value < 5 ether){
      return 0;
    }
    if (_value < 15 ether){
      return 2;
    }
    if (_value < 30 ether){
      return 5;
    }
    if (_value < 50 ether){
      return 8;
    }
    return 10;
  }
  
  //fallback function (when investor send ether to contract)
  function() public payable{
    require(isIco(now));
    require(buy(msg.sender,msg.value, now)); //redirect to func buy
  }

  //function buy Tokens
  function buy(address _address, uint _value, uint _time) internal returns (bool){
    uint tokensForSend = etherToTokens(_value,_time);

    require (tokensForSend >= minDeposit);

    tokensSold = tokensSold.add(tokensForSend);
    ethCollected = ethCollected.add(_value);

    token.sendCrowdsaleTokens(_address,tokensForSend);
    etherDistribution1.transfer(this.balance/2);
    etherDistribution2.transfer(this.balance);

    return true;
  }

  function manualSendTokens (address _address, uint _tokens) public onlyTechSupport {
    token.sendCrowdsaleTokens(_address, _tokens);
    tokensSold = tokensSold.add(_tokens);
  }
  

  //convert ether to tokens (without decimals)
  function etherToTokens(uint _value, uint _time) public view returns(uint res) {
    res = _value.mul((uint)(10).pow(decimals))/(tokenPrice);
    uint bonus = timeBasedBonus(_time).add(volumeBasedBonus(_value));
    res = res.add(res.mul(bonus)/100);
  }

  function endIco () public {
    require(msg.sender == owner || msg.sender == techSupport);
    require(now > icoFinish + 5 days);
    token.burnTokens(teamAddress, bountyAddress, tokensSold);
  }
  
}