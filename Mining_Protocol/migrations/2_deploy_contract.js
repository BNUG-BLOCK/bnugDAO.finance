//const GovernanceToken = artifacts.require("GovernanceToken");
const BNUGDAO_Mining = artifacts.require("BNUGDAO_Mining");

module.exports = function (deployer) {
  //deployer.deploy(GovernanceToken);
  deployer.deploy(
    BNUGDAO_Mining, 
    "0x6C233982566E7f714C9FB31508Ec6f4A5d9C5f12",   //BNUG Token
    "0xF2DEDCE1e760c42d8705F85C2a2F87Ff2f94b237"    //BNUGDAO Token
  );
};
