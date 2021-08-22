pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/util/math/SafeMath.sol";

contract BNUGToken is ERC20 {
  address contractCreator;
  uint private possibleSupply_ = 200000000 * 10 ** 18;
  uint private _totalSupply = 0;
  mapping(address => uint) private balances;
  mapping(address => mapping(address => uint)) allowed;

  event Mint(address minter, uint minted);
  event Burn(uint indexed burned);

  modifier onlyCreator {
    require(msg.sender == contractCreator, "Only the contract creator can execute this function");
    _;
  }

  constructor(address creator) public ERC20("Blockchain Nigeria User Group", "BNUG") {
    contractCreator = creator;
    balances[contractCreator] = 0.723 * possibleSupply_;
    _totalSupply = SafeMath.add(_totalSupply, balances[contractCreator]);
  }

  function totalSupply() public view virtual override returns (uint) {
    return SafeMath.sub(_totalSupply, balances[address(0)]);
  }

  function decimals() public view virtual override returns (uint) {
    return 18;
  }

  function balanceOf(address a) public view virtual override returns (uint256) {
    return balances[a];
  }

  function mint(uint amount) public  (bool) {
    uint supply = SafeMath.add(_totalSupply, amount);
    require(supply <= possibleSupply_, "Cannot exceed possible supply");
    balances[contractCreator] = SafeMath.add(balances[contractCreator], amount);
    _totalSupply = supply;
    emit Mint(msg.sender, amount);
    return true;
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
      allowed[from][msg.sender] = SafeMath.sub(allowed[from][msg.sender], amount);
    }
    require(balances[from] >= amount, "Not enough balance");
    balances[from] = SafeMath.sub(balances[from], amount);
    balances[to] = SafeMath.add(balances[to], amount);
    emit Transfer(from, to, amount);
    return true;
  }
}