pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"
import "@openzeppelin/contracts/access/Ownable.sol";


contract BNUGToken is ERC20Burnable, Ownable {

  constructor(uint256 _totalSupply) ERC20("Blockchain Nigeria User Group", "BNUG") Ownable() public {
    _mint(msg.sender, _totalSupply);
  }

  function returnERC20(
    address _token, 
    address _to, 
    uint256 amount) 
  external onlyOwner() returns(bool success) {
    require(
      _token != address(0), 
      "Token address cannot be zero address"
    );
    require(
      _to != address(0), "Cannot transfer to zero address"
    );
    require(
      IERC20(_token)
        .balanceOf(address(this)) >= amount, 
        "Insufficient token balance"
      );
    IERC20(_token).transfer(_to, amount);
    return true;
  }
}
