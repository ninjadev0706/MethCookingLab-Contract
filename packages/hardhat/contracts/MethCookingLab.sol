// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MethCookingLab is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Staker {
        uint256 stakedAmount;
        uint256 stakingTime;
        bool claimed;
        bool shilled;
    }

    IERC20 public token;
    IERC20 public wETH;

    uint256 public totalStakedAmount;
    uint256 public minStakingDuration;
    uint256 public minimumShillCount = 3;
    uint256 public maxStakerCount = 30;

    // Date timestamp when token sale start
    uint256 public startTime;
    // Date timestamp when token sale ends
    uint256 public endTime;
    
    mapping(address => Staker) public stakers;
    address[] public stakerAddresses;

    constructor(address _tokenAddress, address _wETHAddress) {
        token = IERC20(_tokenAddress);
        wETH = IERC20(_wETHAddress);
    }

    // set duration for min staking
    function setMinStakingDuration(uint256 _minStakingDuration) external onlyOwner {  
        minStakingDuration = _minStakingDuration;
    }

    // set number of stakers
    function setMaxStakerCount(uint256 _maxStakerCount) external onlyOwner {  
        maxStakerCount = _maxStakerCount;
    }

    // set end time of staking
    function setEndTime(uint256 _endTime) external onlyOwner {  
        endTime = _endTime;
    }

    // Stake tokens to Staking Contract
    function stake(uint256 _amount) public {
        require(stakerAddresses.length < maxStakerCount, "Staking slots are full");
        require(_amount >= token.totalSupply().mul(5).div(1000), "Insufficient token balance");
        require(block.timestamp < endTime, "Staking duration is ended");
        token.safeTransferFrom(address(msg.sender), address(this), _amount);
        if(stakers[msg.sender].stakedAmount == 0) {
            stakers[msg.sender] = Staker(_amount, block.timestamp, false, false);
            stakerAddresses.push(msg.sender);
        } else {
            stakers[msg.sender] = Staker((stakers[msg.sender].stakedAmount.add(_amount)), block.timestamp, false, false);
        }
        totalStakedAmount = totalStakedAmount.add(_amount);
    }

    // unstake wETH from Staking Contract

    function unstake() public {
        require(stakers[msg.sender].stakedAmount > 0, "No staked amount");
        require(block.timestamp >= endTime, "Staking duration is not ended yet.");

        token.safeTransfer(address(msg.sender), stakers[msg.sender].stakedAmount);
        stakers[msg.sender].stakedAmount = 0;
    }

    // claim wETH from Staking Contract
    function claim() public {
        require(stakers[msg.sender].stakedAmount > 0, "No staked amount");
        require(!stakers[msg.sender].claimed, "Already claimed");
        require(stakers[msg.sender].shilled, "Not enough shilling");
        require(block.timestamp >= stakers[msg.sender].stakingTime + minStakingDuration, "Minimum staking duration not reached");
        require(block.timestamp >= endTime, "Staking duration is not ended yet.");

        uint256 reward = calculateReward(msg.sender);
        wETH.safeTransfer(address(msg.sender), reward);
        stakers[msg.sender].claimed = true;
    }

    // calculate the reward amount
    function calculateReward(address _staker) internal view returns (uint256) {
        uint256 reward = (wETH.balanceOf(address(this)).mul(stakers[_staker].stakedAmount)).div(totalStakedAmount);
        return reward;
    }

    // check if shill to twitter
    function shill(address _staker) public {
        // require(stakers[_staker].stakedAmount > 0, "No staked amount");
        require(!stakers[_staker].shilled, "Already shilled");

        stakers[_staker].shilled = true;
    }

    // Withdraw. EMERGENCY ONLY.

    function emergencyWithdraw() external onlyOwner {
        // =============================================================================

        // This will payout the owner 100% of the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function emergencyRewardWithdraw(address _tokenAddr) external onlyOwner {
        require(IERC20(_tokenAddr).balanceOf(address(this)) > 0, "Sufficient Token balance");
        
        IERC20(_tokenAddr).safeTransfer(address(msg.sender), IERC20(_tokenAddr).balanceOf(address(this)));
    }
}