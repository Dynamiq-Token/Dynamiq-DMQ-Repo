// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable {
    IERC20 public immutable stakingToken;
    uint256 public rewardRate = 100; 
    uint256 public totalStaked;
    uint256 public APR = 88; 
    address public rewardsWallet;

    struct StakeInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastUpdated;
    }

    mapping(address => StakeInfo) public stakers;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    constructor(address _stakingToken, address _rewardsWallet) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        rewardsWallet = _rewardsWallet;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        stakingToken.transferFrom(msg.sender, address(this), amount);
        
        StakeInfo storage staker = stakers[msg.sender];

        uint256 pending = pendingRewards(msg.sender);
        staker.rewardDebt += pending; 
        staker.amount += amount;
        staker.lastUpdated = block.timestamp; 
        totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    function getStakedAmount(address user) external view returns (uint256) {
        return stakers[user].amount;
    }

    function totalEarnedRewards(address user) external view returns (uint256) {
        return stakers[user].rewardDebt + pendingRewards(user);
    }

    function emergencyWithdraw() external {
        StakeInfo storage staker = stakers[msg.sender];
        require(staker.amount > 0, "Nothing to withdraw");

        uint256 amount = staker.amount;
        staker.amount = 0;
        staker.rewardDebt = 0;
        staker.lastUpdated = block.timestamp; 
        totalStaked -= amount;
        
        stakingToken.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() public {
        StakeInfo storage staker = stakers[msg.sender];
        
        uint256 reward = pendingRewards(msg.sender);
        require(reward > 0, "No rewards to claim");

        staker.rewardDebt = 0;
        staker.lastUpdated = block.timestamp; 
        stakingToken.transferFrom(rewardsWallet, msg.sender, reward); 
        emit RewardsClaimed(msg.sender, reward);
    }

    function unstake(uint256 amount) external {
        StakeInfo storage staker = stakers[msg.sender];
        require(staker.amount >= amount, "Insufficient balance");

        uint256 reward = pendingRewards(msg.sender);
        if (reward > 0) {
            stakingToken.transferFrom(rewardsWallet, msg.sender, reward);
            emit RewardsClaimed(msg.sender, reward);
        }

        staker.amount -= amount;
        staker.lastUpdated = block.timestamp;
        totalStaked -= amount;

        stakingToken.transfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    function fundRewards(uint256 amount) external onlyOwner {
        require(stakingToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        stakingToken.transferFrom(msg.sender, address(this), amount);
    }

    function setAPR(uint256 newAPR) external onlyOwner {
        require(newAPR > 0, "APR must be positive");
        APR = newAPR; 
    }

    function pendingRewards(address user) public view returns (uint256) {
        StakeInfo storage staker = stakers[user];

        if (staker.amount == 0) {
            return 0; 
        }

        uint256 timeElapsed = block.timestamp - staker.lastUpdated;
        uint256 yearlyRewards = (staker.amount * APR) / 100;
        uint256 rewards = (yearlyRewards * timeElapsed) / (365 days);

        return rewards; 
    }
}