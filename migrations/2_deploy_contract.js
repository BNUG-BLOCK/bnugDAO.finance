//const GovernanceToken = artifacts.require("GovernanceToken");
const BNUGToken = artifacts.require("BNUGToken");

module.exports = function (deployer) {
  //deployer.deploy(GovernanceToken);
  deployer.deploy(BNUGToken, web3.utils.toWei("200000000"));
};