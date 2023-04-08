pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Airdrop is VRFConsumerBase {
    address public owner;
    IERC20 public token;
    mapping(address => bool) public hasReceivedAirdrop;
    uint256 public airdropAmount;
    uint256 public totalAirdrop;
    uint256 public randomResult;
    bytes32 public requestId;
    uint256 public oracleFee;
    AggregatorV3Interface internal priceFeed;

    event AirdropSent(address recipient, uint256 amount);
    event RandomNumberGenerated(uint256 randomNumber);
    event RequestIdGenerated(bytes32 requestId);

    constructor(
        address _tokenAddress,
        uint256 _airdropAmount,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee,
        address _priceFeed
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
        airdropAmount = _airdropAmount;
        oracleFee = _fee;
        priceFeed = AggregatorV3Interface(_priceFeed);
        token.approve(address(this), _airdropAmount * 100);
    }

    function requestRandomNumber(uint256 seed) external onlyOwner {
        require(LINK.balanceOf(address(this)) >= oracleFee, "Not enough LINK to pay oracle fee");
        requestId = requestRandomness(keyHash, oracleFee, seed);
        emit RequestIdGenerated(requestId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        emit RandomNumberGenerated(randomness);
    }

    function sendAirdrop(address[] memory recipients) external onlyOwner {
        require(randomResult > 0, "Random number not generated");
        uint256 startIndex = randomResult % recipients.length;

        for (uint256 i = 0; i < 100; i++) {
            uint256 index = (startIndex + i) % recipients.length;

            if (!hasReceivedAirdrop[recipients[index]]) {
                require(token.balanceOf(address(this)) >= airdropAmount, "Insufficient token balance in contract");
                require(token.transfer(recipients[index], airdropAmount), "Airdrop failed");
                hasReceivedAirdrop[recipients[index]] = true;
                totalAirdrop += airdropAmount;
                emit AirdropSent(recipients[index], airdropAmount);
            }
        }
    }

        function withdrawTokens() external onlyOwner {
        uint256 tokenBalance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, tokenBalance), "Token withdrawal failed");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
}
