//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @title FundAI
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface IAntisnipe {
    function assureCanTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external;
}

contract FundAI is ERC20, Ownable {
    /// @dev address of antisnipe contract
    IAntisnipe public antisnipe;
    /// @dev status of antisnipe
    bool public antisnipeDisable;

    constructor(address owner, address holder) ERC20('DFund AI', 'FUNDAI') {
        _mint(holder, 100_000_000 * 10 ** decimals());
        _transferOwnership(owner);
    }

    /// @inheritdoc ERC20
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        /// antisnipe call
        if (!antisnipeDisable && address(antisnipe) != address(0))
            antisnipe.assureCanTransfer(msg.sender, from, to, amount);
    }

    /// @dev disables antisnipe **one-way!!!** (only owner)
    function setAntisnipeDisable() external onlyOwner {
        require(!antisnipeDisable);
        antisnipeDisable = true;
    }

    /// @dev sets new antisnipe address (only owner)
    /// @param addr address of antisnipe
    function setAntisnipeAddress(address addr) external onlyOwner {
        antisnipe = IAntisnipe(addr);
    }
}
