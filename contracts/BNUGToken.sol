pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract BNUGToken is ERC20Burnable {
  uint private _totalSupply = 200000000 * 10 ** 18;

  constructor() public ERC20("Blockchain Nigeria User Group", "BNUG") {
    _mint(msg.sender, _totalSupply);
  }
}