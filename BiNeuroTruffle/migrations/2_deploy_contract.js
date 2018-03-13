var Token = artifacts.require("./BineuroToken.sol");
var Crowdsale = artifacts.require("./Crowdsale.sol");

var address = web3.eth.accounts[0];
module.exports = function(deployer) {
  deployer.deploy(Token,address).then(function(){
  	return deployer.deploy(Crowdsale,Token.address);
  })
};
