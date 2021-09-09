//"SPDX-License-Identifier: MIT"

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBNUGDAO is IERC20 {
  
  /**
   * @dev Creates `_amount` tokens from the null account to `_to`.
   *
   * Emits a {Transfer} event.
   */
  function mintToken(address _to, uint _amount) external;
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
} 

library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                //hex'd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66' // init code hash
                hex'ecba335299a6693cb2ebc4782e74669b84290b6378ea3a3873c7231a8d7d1074'   // Change to INIT_CODE_PAIR_HASH of Pancake Factory
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

contract BNUGDAO_Mining is 
    Ownable, 
    ReentrancyGuard {

    using SafeMath for uint;
   
    IBNUGDAO private BNUGDAO;
    IERC20 private BNUG;
    IERC20 private lpToken;
    
    IPancakeRouter private pancakeRouter;
    IPancakeFactory private iPancakeFactory;
    
    uint public liquidityRewardPerBlock;
    uint public stakingRewardPerBlock;

    struct User {
        uint lpAmount;
        uint stakeAmount;
        uint checkpoint;
    }

    mapping(address => User) private _users;
    
    event LiquidityAdded(
        address indexed sender, 
        uint liquidity, 
        uint amountBNB, 
        uint amountBNUG
    );

    event StakeAdded(
        address indexed sender, 
        uint amount
    );

    event LiquidityWithdrawn(
        address indexed sender, 
        uint liquidity, 
        uint amountBNB, 
        uint amountBNUG
    );

    event StakeWithdrawn(
        address indexed sender,
        uint amountBNUG
    );

    event NewClaim(
        address indexed sender,
        uint amount
    );

    event BlockRewardSet(
        address owner,
        uint newreward,
        string rewardType
    );
    
    constructor(
        address _BNUGAddress,
        address _BNUGDAOAddress,
        uint _liquidityRewardPerBlock,
        uint _stakingRewardPerBlock) 
        public Ownable() {
    
        BNUG = IERC20(_BNUGAddress);
        BNUGDAO = IBNUGDAO(_BNUGDAOAddress);

        liquidityRewardPerBlock = _liquidityRewardPerBlock;
        stakingRewardPerBlock = _stakingRewardPerBlock;
        
        pancakeRouter = IPancakeRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        iPancakeFactory = IPancakeFactory(pancakeRouter.factory());

        address _lpToken = iPancakeFactory.getPair(
            _BNUGAddress, 
            pancakeRouter.WETH()
        );

        require(
            _lpToken != address(0), 
            "Pair must first be created on pancakeswap"
        );

        lpToken = IERC20(_lpToken);
    }
    
    function addLiquidity(
        uint _BNUGAmount)
        external payable nonReentrant() returns(bool success) {
        
        uint rate = _priceOracle(
            _BNUGAmount, 
            address(BNUG),
            pancakeRouter.WETH()
        );

        require(
            msg.value == rate, 
            "Must send equal value in BNB"
        );
        
        require(
            BNUG.transferFrom(
                msg.sender,
                address(this),
                _BNUGAmount
            ),
            "Error in withdrawing tokens from sender"
        );

        User storage user = _users[msg.sender];
        
        if (user.checkpoint == 0) user.checkpoint = block.number;
        else _distribute(msg.sender);
        
        BNUG.approve(address(pancakeRouter), _BNUGAmount);

        (uint amountBNUG, uint amountBNB, uint liquidity) = 
        pancakeRouter.addLiquidityETH{value: msg.value}(
            address(BNUG), 
            _BNUGAmount, 
            0, 
            0, 
            address(this), 
            block.timestamp
        );
        
        user.lpAmount = user.lpAmount.add(liquidity);

        emit LiquidityAdded(
            msg.sender, liquidity, 
            amountBNB, amountBNUG
        );
        return true;
    }

    function removeLiquidity(
        uint _lpAmount) 
        external nonReentrant() returns(bool success) {
        
        User storage user = _users[msg.sender];
        uint liquidity = user.lpAmount;
        
        require(
            _lpAmount > 0 
            && _lpAmount <= liquidity, 
            "Not enough liquidity"
        );

        _distribute(msg.sender);  

        user.lpAmount = liquidity.sub(_lpAmount); 
        
        lpToken.approve(
            address(pancakeRouter), 
            _lpAmount
        );                                       
        
        (uint amountBNUG, uint amountBNB) = 
        pancakeRouter.removeLiquidityETH(
            address(BNUG),
            _lpAmount,
            1,
            1,
            msg.sender,
            block.timestamp
        );

        if (
            user.lpAmount == 0 
            && user.stakeAmount == 0
        ) user.checkpoint = 0;
        
        emit LiquidityWithdrawn(
            msg.sender, _lpAmount, 
            amountBNB, amountBNUG
        );
        return true;
    }

    function stake(
        uint _bnugAmount)
        external nonReentrant() returns(bool success) {

        require(
            BNUG.transferFrom(
                msg.sender, 
                address(this), 
                _bnugAmount
            ),
            "Error in withdrawing tokens from sender"
        );

        User storage user = _users[msg.sender];
        
        if (user.checkpoint == 0) user.checkpoint = block.number;
        else _distribute(msg.sender);

        user.stakeAmount = user.stakeAmount.add(_bnugAmount);

        emit StakeAdded(msg.sender, _bnugAmount);
        return true;
    }

    function unstake(
        uint _bnugAmount)
        external nonReentrant() returns(bool success) {

        User storage user = _users[msg.sender];
        uint stakeAmount = user.stakeAmount;
        
        require(
            _bnugAmount > 0 
            && _bnugAmount <= stakeAmount, 
            "Not enough stakes"
        );

        _distribute(msg.sender);  

        user.stakeAmount = stakeAmount.sub(_bnugAmount);
        BNUG.transfer(msg.sender, _bnugAmount);

        if (
            user.lpAmount == 0 
            && user.stakeAmount == 0
        ) user.checkpoint = 0;
        
        emit StakeWithdrawn(msg.sender, _bnugAmount);
        return true;
    }

    function claim()
        external nonReentrant() returns(bool success) {

        User memory user = _users[msg.sender];

        require(
            block.number > user.checkpoint
            && (
                user.lpAmount > 0 
                || user.stakeAmount > 0
            ),
            "Nothing available to claim"
        );

        _distribute(msg.sender);
        return true;
    }

    function setLiquidityRewardPerBlock(
        uint _newReward)
        external onlyOwner() {

        require(
            liquidityRewardPerBlock != _newReward,
            "Error: already set"
        );

        liquidityRewardPerBlock = _newReward;
        emit BlockRewardSet(msg.sender, _newReward, "liquidity");
    }

    function setStakingRewardPerBlock(
        uint _newReward)
        external onlyOwner() {

        require(
            stakingRewardPerBlock != _newReward,
            "Error: already set"
        );

        stakingRewardPerBlock = _newReward;
        emit BlockRewardSet(msg.sender, _newReward, "staking");
    }

    function getUserClaimableRewards(
        address _user)
        public view returns(uint fromLP, uint fromStaking, uint total) {

        User memory user = _users[_user];

        uint checkpoint = user.checkpoint;
        uint divFactor = 10 ** 6;
        (uint bnugProvided,) = getUserLiquidity(_user);
        fromLP = (
            bnugProvided
            .mul((block.number.sub(checkpoint))))
            .mul(liquidityRewardPerBlock.div(divFactor));
        fromStaking = (
            user.stakeAmount
            .mul((block.number.sub(checkpoint))))
            .mul(stakingRewardPerBlock.div(divFactor));
        total = fromLP.add(fromStaking);
    }
    
    function getUserLPAmount(
        address _user)
        public view returns(uint LP_Amount) {

        LP_Amount = _users[_user].lpAmount;
    }
    
    function getTotalLPAmount(
        ) public view returns(uint Total_LP_Amount) {

        Total_LP_Amount = lpToken.balanceOf(address(this));
    }

    function priceOracle(
        uint _bnugAmount)
        external view returns(uint rate) {

        rate = _priceOracle(
            _bnugAmount, 
            address(BNUG),
            pancakeRouter.WETH()
        );
    }
    
    function lpAddress(
        ) external view returns(address LP_Address) {
        
        return address(lpToken);
    }

    function getUserLiquidity(
        address _user) 
        public view returns(uint provided_BNUG, uint provided_BNB) {
        
        uint total = lpToken.totalSupply();
        uint SCALAR = 10 ^ 32;
        uint ratio = ((_users[_user].lpAmount).mul(SCALAR)).div(total);
        uint bnugHeld = BNUG.balanceOf(address(lpToken));
        uint bnbHeld = IERC20(
            pancakeRouter.WETH()).balanceOf(address(lpToken)
        );
        
        return (
            (ratio.mul(bnugHeld)).div(SCALAR), 
            (ratio.mul(bnbHeld)).div(SCALAR)
        );
    }

    function _distribute(
        address _user) 
        private {
        
        User storage user = _users[_user];
        uint checkpoint = user.checkpoint;
        
        if (block.number > checkpoint) {
            (,,uint rewards) = getUserClaimableRewards(_user);
            if (rewards > 0) {
                BNUGDAO.mintToken(_user, rewards);
                user.checkpoint = block.number;
                emit NewClaim(msg.sender, rewards);
            }
        }
    }

    function _priceOracle(
        uint _amount, 
        address _tokenA, 
        address _tokenB) 
        private view returns(uint rate) {
        
        (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(
            address(iPancakeFactory), _tokenA, _tokenB
        );
        
        return PancakeLibrary.quote(_amount, reserveA, reserveB);
    }
}