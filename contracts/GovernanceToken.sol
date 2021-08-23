//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract GovernanceToken is ERC20Burnable, Ownable {

    mapping(address => bool) private isMinter;

    event ReturnedERC20(
        address indexed token, 
        address indexed receiver, 
        uint amount
    );
    event MinterAdded(
        address indexed caller, 
        address indexed minter, 
        uint timestamp
    );
    event MinterRemoved(
        address indexed caller, 
        address indexed minter, 
        uint timestamp
    );

    constructor(
        ) ERC20(
            "BNUG Governance Token", 
            "BNUGDAO"
        ) 
        Ownable() {}

    function mintToken(
        address _to, 
        uint _amount)
        external {

        require(
            isMinter[msg.sender],
            "only minter allowed"
        );
        
        _mint(_to, _amount);

    }

    function returnERC20(
        address _token, 
        address _to, 
        uint _amount) 
        external onlyOwner() {
        
        require(
            _token != address(0), 
            "invalid _token address"
        );
        require(
            _to != address(0), 
            "invalid _to address"
        );
        require(
            IERC20(_token).balanceOf(
                address(this)) >= _amount,
            "insufficient token balance"
        );

        IERC20(_token).transfer(_to, _amount);  
        emit ReturnedERC20(_token, _to, _amount);
    }

    function addMinter(
        address _minter)
        external onlyOwner() {
        
        _addMinter(_minter);
    }

    function removeMinter(
        address _minter)
        external onlyOwner() {
        
        _removeMinter(_minter);
    }

    function hasMinterRight(
        address _addr)
        external view returns(bool canMint) {
        
        return isMinter[_addr];
    }

    function _addMinter(
        address _minter)
        internal {
        
        require(
            !isMinter[_minter], 
            "_minter is already a minter"
        );
        
        require(
            Address.isContract(_minter), 
            "_minter must be a smart contract"
        );

        isMinter[_minter] = true;
        emit MinterAdded(msg.sender, _minter, block.timestamp);
    }

    function _removeMinter(
        address _minter)
        internal {
        
        require(
            isMinter[_minter], 
            "_minter is not a minter"
        );

        isMinter[_minter] = false;
        emit MinterRemoved(msg.sender, _minter, block.timestamp);
    }
}