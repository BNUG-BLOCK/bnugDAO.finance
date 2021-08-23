pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract BNUGToken is ERC20Burnable {
  address contractCreator;
  uint private _totalSupply = 200000000 * 10 ** 18;
  mapping(address => uint) private balances;
  mapping(address => mapping(address => uint)) allowed;

  event Burn(uint indexed burned);

  constructor(address creator) public ERC20("Blockchain Nigeria User Group", "BNUG") {
    contractCreator = creator;
    balances[contractCreator] = _totalSupply;
  }

  function totalSupply() public view virtual override returns (uint) {
    return _totalSupply - balances[address(0)];
  }

  function decimals() public view virtual override returns (uint) {
    return 18;
  }

  function balanceOf(address a) public view virtual override returns (uint256) {
    return balances[a];
  }

  function burn(uint amount) public onlyCreator {
    transferFrom(contractCreator, address(0), amount);
    emit Burn(amount);
  }

  function approve(address spender, uint spendable) public virtual override returns (bool) {
    allowed[msg.sender][spender] = spendable;
    emit Approval(msg.sender, spender, spendable);
    return true;
  }

  function allowance(address owner, address spender) public virtual override returns (uint) {
    return allowed[owner][spender];
  }

  function transfer(address to, uint amount) public virtual override returns (bool) {
    return transferFrom(msg.sender, to, amount);
  }

  function transferFrom(address from, address to, uint amount) public virtual override returns (bool) {
    if (from != msg.sender && allowed[from][msg.sender] > uint(int(-1))) {
      require(allowed[from][msg.sender] >= amount, "No approval given");
      allowed[from][msg.sender] = allowed[from][msg.sender] - amount;
    }
    require(balances[from] >= amount, "Not enough balance");
    balances[from] = balances[from] -amount;
    balances[to] = balances[to] - amount;
    emit Transfer(from, to, amount);
    return true;
  }
}