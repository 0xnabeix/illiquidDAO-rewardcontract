// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IlliquidDAOStaking is ERC20("veIlliquidDAO", "veIlliquidDAO"), Ownable {
    using SafeERC20 for IERC20;
    using SafeCast for int256;
    using SafeCast for uint256;

    struct Config {
        // Timestamp in seconds is small enough to fit into uint64
        uint64 periodFinish;
        uint64 periodStart;

        // Staking incentive rewards to distribute in a steady rate
        uint128 totalReward;
    }

    IERC20 public illiquidDAO;
    Config public config;

    /*
     * Construct an IlliquidDAOStaking contract.
     *
     * @param _illiquidDAOAmount the contract address of IlliquidDAOAmount token
     * @param _periodStart the initial start time of rewards period
     * @param _rewardsDuration the duration of rewards in seconds
     */
    constructor(IERC20 _illiquidDAO, uint64 _periodStart, uint64 _rewardsDuration) {
        require(address(_illiquidDAO) != address(0), "IlliquidDAOStaking: _illiquidDAOAmount cannot be the zero address");
        illiquidDAO = _illiquidDAO;
        setPeriod(_periodStart, _rewardsDuration);
    }

    /*
     * Add IlliquidDAOAmount tokens to the reward pool.
     *
     * @param _illiquidDAOAmountAmount the amount of IlliquidDAOAmount tokens to add to the reward pool
     */
    function addRewardIlliquidDAO(uint256 _illiquidDAOAmount) external {
        Config memory cfg = config;
        require(block.timestamp < cfg.periodFinish, "IlliquidDAOStaking: Adding rewards is forbidden");

        illiquidDAO.safeTransferFrom(msg.sender, address(this), _illiquidDAOAmount);
        cfg.totalReward += _illiquidDAOAmount.toUint128();
        config = cfg;
    }

    /*
     * Set the reward peroid. If only possible to set the reward period after last rewards have been
     * expired.
     *
     * @param _periodStart timestamp of reward starting time
     * @param _rewardsDuration the duration of rewards in seconds
     */
    function setPeriod(uint64 _periodStart, uint64 _rewardsDuration) public onlyOwner {
        require(_periodStart >= block.timestamp, "IlliquidDAOStaking: _periodStart shouldn't be in the past");
        require(_rewardsDuration > 0, "IlliquidDAOtaking: Invalid rewards duration");

        Config memory cfg = config;
        require(cfg.periodFinish < block.timestamp, "IlliquidDAOStaking: The last reward period should be finished before setting a new one");

        uint64 _periodFinish = _periodStart + _rewardsDuration;
        config.periodStart = _periodStart;
        config.periodFinish = _periodFinish;
        config.totalReward = 0;
    }

    /*
     * Returns the staked illiquidDAOAmount + release rewards
     *
     * @returns amount of available illiquidDAOAmount
     */
    function getIlliquidDAOPool() public view returns(uint256) {
        return illiquidDAO.balanceOf(address(this)) - frozenRewards();
    }

    /*
     * Returns the frozen rewards
     *
     * @returns amount of frozen rewards
     */
    function frozenRewards() public view returns(uint256) {
        Config memory cfg = config;

        uint256 time = block.timestamp;
        uint256 remainingTime;
        uint256 duration = uint256(cfg.periodFinish) - uint256(cfg.periodStart);

        if (time <= cfg.periodStart) {
            remainingTime = duration;
        } else if (time >= cfg.periodFinish) {
            remainingTime = 0;
        } else {
            remainingTime = cfg.periodFinish - time;
        }

        return remainingTime * uint256(cfg.totalReward) / duration;
    }

    /*
     * Staking specific amount of IlliquidDAOAmount token and get corresponding amount of veIlliquidDAOAmount
     * as the user's share in the pool
     *
     * @param _illiquidDAOAmountAmount
     */
    function enter(uint256 _illiquidDAOAmount) external {
        require(_illiquidDAOAmount > 0, "IlliquidDAOStaking: Should at least stake something");

        uint256 totalIlliquidDAO = getIlliquidDAOPool();
        uint256 totalShares = totalSupply();

        illiquidDAO.safeTransferFrom(msg.sender, address(this), _illiquidDAOAmount);

        if (totalShares == 0 || totalIlliquidDAO == 0) {
            _mint(msg.sender, _illiquidDAOAmount);
        } else {
            uint256 _share = _illiquidDAOAmount * totalShares / totalIlliquidDAO;
            _mint(msg.sender, _share);
        }
    }

    /*
     * Redeem specific amount of veIlliquidDAOAmount to IlliquidDAOAmount tokens according to the user's share in the pool.
     * veIlliquidDAOAmount will be burnt.
     *
     * @param _share
     */
    function leave(uint256 _share) external {
        require(_share > 0, "IlliquidDAOStaking: Should at least unstake something");

        uint256 totalIlliquidDAO = getIlliquidDAOPool();
        uint256 totalShares = totalSupply();

        _burn(msg.sender, _share);

        uint256 _illiquidDAOAmount = _share * totalIlliquidDAO / totalShares;
        illiquidDAO.safeTransfer(msg.sender, _illiquidDAOAmount);
    }
}