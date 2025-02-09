// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DynamiqToken is ERC20, Ownable {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10**18;
    uint256 public constant AUTO_STAKE_BPS = 50; 
    address public stakingContract;
    address public immutable rewardsWallet;
    address public immutable marketingWallet;
    address public immutable devWallet;
    address public immutable liquidityWallet;
    uint256 public devUnlockTime;
    uint256 public devReleasedPercentage;

    event AutoStaked(address indexed user, uint256 amount);
    event DevTokensReleased(address indexed devWallet, uint256 amount);
    event StakingContractUpdated(address indexed newStakingContract);

    constructor(
        address _devWallet, 
        address _stakingContract, 
        address _marketingWallet, 
        address _rewardsWallet, 
        address _liquidityWallet
    ) ERC20("Dynamiq", "DMQ") Ownable(msg.sender) {
        devWallet = _devWallet;
        stakingContract = _stakingContract;
        marketingWallet = _marketingWallet;
        rewardsWallet = _rewardsWallet;
        liquidityWallet = _liquidityWallet;
        devUnlockTime = block.timestamp + 180 days;
        devReleasedPercentage = 0;

        _mint(rewardsWallet, (TOTAL_SUPPLY * 40) / 100); 
        _mint(marketingWallet, (TOTAL_SUPPLY * 20) / 100); 
        _mint(address(this), (TOTAL_SUPPLY * 15) / 100); 
        _mint(liquidityWallet, (TOTAL_SUPPLY * 25) / 100); 
    }

    function setStakingContract(address _stakingContract) external onlyOwner {
        require(_stakingContract != address(0), "Invalid staking contract address");
        stakingContract = _stakingContract;
        emit StakingContractUpdated(_stakingContract);
    }

    modifier onlyStakingContract() {
        require(msg.sender == stakingContract, "Not staking contract");
        _;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (msg.sender == stakingContract || recipient == stakingContract) {
            return super.transfer(recipient, amount);
        }

        uint256 stakeAmount = (amount * AUTO_STAKE_BPS) / 10000;
        uint256 transferAmount = amount - stakeAmount;

        require(msg.sender != rewardsWallet || recipient == stakingContract, "Rewards locked");

        if (stakeAmount > 0 && rewardsWallet != address(0)) {
            _transfer(_msgSender(), rewardsWallet, stakeAmount);
            emit AutoStaked(_msgSender(), stakeAmount);
        }

        return super.transfer(recipient, transferAmount);
    }


    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (sender == stakingContract || recipient == stakingContract) {
            return super.transferFrom(sender, recipient, amount);
        }

        _autoStake(sender, amount);
        return super.transferFrom(sender, recipient, amount);
    }

    function _autoStake(address sender, uint256 amount) internal {
        uint256 stakeAmount = (amount * AUTO_STAKE_BPS) / 10000; 
        if (stakeAmount > 0 && rewardsWallet != address(0)) {
            _transfer(sender, rewardsWallet, stakeAmount);
            emit AutoStaked(sender, stakeAmount);
        }
    }

    function approveStakingContract() external {
        require(msg.sender == rewardsWallet, "Only rewards wallet can approve");
        _approve(rewardsWallet, stakingContract, type(uint256).max);
    }

    function releaseDevTokens() external {
        require(msg.sender == devWallet, "Only dev wallet can release tokens");
        require(block.timestamp >= devUnlockTime, "Dev tokens are still locked");
        require(devReleasedPercentage < 100, "All dev tokens have been released");

        uint256 totalDevAllocation = (TOTAL_SUPPLY * 15) / 100;
        uint256 releaseAmount = (totalDevAllocation * 10) / 100; // 10% per month

        _transfer(address(this), devWallet, releaseAmount);
        devReleasedPercentage += 10;
        devUnlockTime += 30 days;

        emit DevTokensReleased(devWallet, releaseAmount);
    }
}