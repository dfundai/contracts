// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract Airdrop is AutomationCompatible {
    struct StakeHolder {
        address stakeHolderAddress;
        uint256 amount;
    }
    
    address public owner;
    LinkTokenInterface public token;
    AggregatorV3Interface internal priceFeed;
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public totalStaked;
    uint256 public minStake;
    uint256 public maxStake;
    uint256 public airdropAmount;
    uint256 public airdropCount;
    mapping(address => uint256) public stakes;
    StakeHolder[] public stakeHolders;

    constructor(
        address _owner,
        address _token,
        address _priceFeed,
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _minStake,
        uint256 _maxStake,
        uint256 _airdropAmount,
        uint256 _airdropCount
    ) {
        owner = _owner;
        token = LinkTokenInterface(_token);
        priceFeed = AggregatorV3Interface(_priceFeed);
        keyHash = _keyHash;
        fee = _fee;
        minStake = _minStake;
        maxStake = _maxStake;
        airdropAmount = _airdropAmount;
        airdropCount = _airdropCount;
    }

    function stake() external payable {
        require(msg.value >= minStake, "Stake amount is too low");
        require(msg.value <= maxStake, "Stake amount is too high");
        totalStaked += msg.value;
        stakes[msg.sender] += msg.value;
        stakeHolders.push(StakeHolder(msg.sender, msg.value));
    }

    function startAirdrop() external onlyOwner {
        require(stakeHolders.length >= airdropCount, "Not enough stakers");
        requestRandomness(keyHash, fee, airdropCount);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(msg.sender == address(automation), "Fulfillment only permitted from Automation");
        uint256[] memory selectedIndexes = new uint256[](airdropCount);
        uint256[] memory amounts = new uint256[](airdropCount);

        for (uint256 i = 0; i < airdropCount; i++) {
            uint256 selectedIndex = uint256(keccak256(abi.encode(randomness, i))) % stakeHolders.length;
            selectedIndexes[i] = selectedIndex;
            uint256 selectedAmount = airdropAmount / airdropCount;
            amounts[i] = selectedAmount;
            require(token.transfer(stakeHolders[selectedIndex].stakeHolderAddress, selectedAmount), "Token transfer failed");
        }

        emit AirdropCompleted(selectedIndexes, amounts);
    }

    function withdraw() external onlyOwner {
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function withdrawLink() external onlyOwner {
        token.transfer(owner, token.balanceOf(address(this)));
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    event AirdropCompleted(uint256[] selectedIndexes, uint256[] amounts);

}
