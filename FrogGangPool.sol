// SPDX-License-Identifier: MIT

/*
使用说明
1.设置挖矿时间
2.转入rewardtoken
3.设置rewardtoken的总数量
*/
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTPoolOne {
    //IERC20 public  stakingToken;
    IERC721 public stakingERC721;
    //IERC20 public  rewardsToken;

    address public owner;

    // Duration of rewards to be paid out (in seconds)
    uint public duration;
    // Timestamp of when the rewards finish
    uint public finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    // Reward to be paid out per second
    uint public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;
    // User address => rewardPerTokenStored

    uint starAt;
    mapping(address => uint) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint) public rewards;

    // Total staked
    uint public totalSupply;
    // User address => staked amount
    mapping(address => uint) public balanceOf;
    //质押NFT address=>tokenId=>isStakeInContract
    mapping(address => mapping(uint => bool)) public NFTStakeIndex;

    uint constant ONE_NFT = 10**18;


    constructor(address _stakingERC721) {
        owner = msg.sender;
        //stakingToken = IERC20(_stakingToken);
        stakingERC721 = IERC721(_stakingERC721);
        //rewardsToken = IERC20(_rewardToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function resetToken(address _stakingERC721) public onlyOwner{
        stakingERC721 = IERC721(_stakingERC721);
        //rewardsToken = IERC20(_rewardToken);

    }

    function stake(uint tokenId) external updateReward(msg.sender) {
        //require(_amount > 0, "amount = 0");
        require(stakingERC721.ownerOf(tokenId) == msg.sender, "not owner of NFT");
        //stakingToken.transferFrom(msg.sender, address(this), _amount);
        stakingERC721.transferFrom(msg.sender, address(this), tokenId);
        balanceOf[msg.sender] += ONE_NFT;
        totalSupply += ONE_NFT;
        NFTStakeIndex[msg.sender][tokenId] = true;//质押NFTindex
    }

    function withdraw(uint tokenId) external updateReward(msg.sender) {
        //require(_amount > 0, "amount = 0");
        require(NFTStakeIndex[msg.sender][tokenId], "NFT not staking");
        balanceOf[msg.sender] -= ONE_NFT;
        totalSupply -= ONE_NFT;
        //stakingToken.transfer(msg.sender, _amount);
        stakingERC721.transferFrom(address(this), msg.sender, tokenId);
    }

    function earned(address _account) public view returns (uint) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }


    //设置可以挖矿的时间，单位s
    function setRewardsDuration(uint _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
        starAt = block.timestamp;
    }
    //可获取的ERC20数量
    function notifyRewardAmount(
        uint _amount
    ) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");


        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }




    function leftingTime() external view returns(uint){
        if((duration + starAt) >= block.timestamp)
            return duration + starAt - block.timestamp;
        else 
            return 0;
        
    }

    function earnedByUser()public view returns (uint) {
        return earned(msg.sender);
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
