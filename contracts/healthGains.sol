// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract HealthGains {
    IERC20 public rewardToken;
    address public admin;

    struct User {
        uint256 streak;
        uint256 lastWorkoutTimestamp;
        uint256 weeklyChallengeCompleted;
        uint256 stakeAmount;
    }

    mapping(address => User) public users;
    uint256 public dailyReward = 10**6;
    uint256 public weeklyChallengeReward = 100**6;
    uint256 public streakRequirement = 7; // 7-day streak to complete the weekly challenge
    uint256 public rewardInterval = 1 days; // Default reward interval is 24 hours
    uint256 public penaltyPercentage = 10; // 10% of the stake lost if streak is broken

    event DailyWorkoutCompleted(address indexed user, uint256 amount);
    event WeeklyChallengeCompleted(address indexed user, uint256 amount);
    event FitnessChallengeJoined(address indexed user);
    event UserReset(address indexed user);
    event Staked(address indexed user, uint256 amount);
    event StakeLost(address indexed user, uint256 amount);
    event RewardIntervalUpdated(uint256 newInterval);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor(address _rewardTokenAddress) {
        rewardToken = IERC20(_rewardTokenAddress);
        admin = msg.sender;
    }

    function _initializeUser(address _user) public {
        // Initialize the user if it's the first time interacting with the contract
        if (users[_user].lastWorkoutTimestamp == 0) {
            users[_user].lastWorkoutTimestamp = block.timestamp;
        }
    }

    function stakeTokens(uint256 _amount) external {
        require(_amount > 0, "Stake amount must be greater than 0");
        
        // Initialize user if necessary
        _initializeUser(msg.sender);
        
        User storage user = users[msg.sender];

        // Transfer the staking amount from user to contract
        rewardToken.transferFrom(msg.sender, address(this), _amount);
        user.stakeAmount += _amount;

        emit Staked(msg.sender, _amount);
    }

    function recordDailyWorkout() external {
        User storage user = users[msg.sender];

        // Ensure the rewardInterval has passed since the last workout
        require(block.timestamp >= user.lastWorkoutTimestamp + rewardInterval, "You can only claim rewards once per interval");

        // Check if the user has missed the workout for more than 2 days
        if (block.timestamp >= user.lastWorkoutTimestamp + 2 days) {
            uint256 penalty = (user.stakeAmount * penaltyPercentage) / 100; // 10% penalty
            user.stakeAmount -= penalty;

            // Transfer the penalty amount to the admin or burn it (here sending to admin)
            rewardToken.transfer(admin, penalty);
            user.streak = 0; // Reset streak

            emit StakeLost(msg.sender, penalty);
        }

        // Update the user's workout data
        user.lastWorkoutTimestamp = block.timestamp;
        user.streak++;

        // Reward the user for completing a daily workout
        rewardToken.transfer(msg.sender, dailyReward);
        emit DailyWorkoutCompleted(msg.sender, dailyReward);

        // If the user has completed the streak requirement, reward them for completing the weekly challenge
        if (user.streak >= streakRequirement) {
            user.weeklyChallengeCompleted++;

            // Reward the user for completing the weekly challenge
            rewardToken.transfer(msg.sender, weeklyChallengeReward);
            emit WeeklyChallengeCompleted(msg.sender, weeklyChallengeReward);
        }
    }

    function joinFitnessChallenge() external {
        User storage user = users[msg.sender];
        require(user.weeklyChallengeCompleted > 0, "Complete a weekly challenge to join");

        // Allow the user to join the fitness challenge
        user.weeklyChallengeCompleted--;
        emit FitnessChallengeJoined(msg.sender);
    }

    function setDailyReward(uint256 _newReward) external onlyAdmin {
        dailyReward = _newReward;
    }

    function setWeeklyChallengeReward(uint256 _newReward) external onlyAdmin {
        weeklyChallengeReward = _newReward;
    }

    function setStreakRequirement(uint256 _newRequirement) external onlyAdmin {
        streakRequirement = _newRequirement;
    }

    function setRewardToken(address _rewardTokenAddress) external onlyAdmin {
        rewardToken = IERC20(_rewardTokenAddress);
    }

    function setRewardInterval(uint256 _newInterval) external onlyAdmin {
        rewardInterval = _newInterval;
        emit RewardIntervalUpdated(_newInterval);
    }

    function getUserInfo(address _user) external view returns (uint256 streak, uint256 lastWorkoutTimestamp, uint256 weeklyChallengeCompleted, uint256 stakeAmount) {
        User storage user = users[_user];
        return (user.streak, user.lastWorkoutTimestamp, user.weeklyChallengeCompleted, user.stakeAmount);
    }

    // Helper function to reset a user's details 
    function resetUser(address _user) external onlyAdmin {
        User storage user = users[_user];
        user.streak = 0;
        user.lastWorkoutTimestamp = 0;
        user.weeklyChallengeCompleted = 0;
        user.stakeAmount = 0;

        emit UserReset(_user);
    }
}
