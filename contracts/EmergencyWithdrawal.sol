// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IBasePool.sol";

contract EmergencyWithdrawal is ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Approved(address indexed user, address indexed pool, address indexed escrow);
    event Unapproved(address indexed user, address indexed pool, address indexed escrow);
    event Withdrawal(address indexed user, address indexed pool, address indexed escrow, uint256 amount);

    // Mapping of user => pool => escrow => approved
    mapping(address => mapping(address => mapping(address => bool))) public approved;

    function approve(address _pool, address _escrow) external {
        approved[msg.sender][_pool][_escrow] = true;
        emit Approved(msg.sender, _pool, _escrow);
    }

    function unapprove(address _pool, address _escrow) external {
        approved[msg.sender][_pool][_escrow] = false;
        emit Unapproved(msg.sender, _pool, _escrow);
    }

    function isApproved(address _user, address _pool, address _escrow) public view returns (bool) {
        return approved[_user][_pool][_escrow];
    }

    function collectEmergency(IBasePool _pool, address _onBehalfOf) external nonReentrant {
        require(isApproved(_onBehalfOf, address(_pool), msg.sender), "Not approved");

        (IERC20 token, , , , , , , , ) = _pool.getPoolInfo();

        // Store the amount of tokens before the withdraw
        uint256 amountBefore = token.balanceOf(address(this));

        (, , , uint256[] memory sharesOverTime, ) = _pool.getLpInfo(_onBehalfOf);

        // Get the last number of shares
        require(sharesOverTime.length > 0, "No shares");
        uint128 shares = uint128(sharesOverTime[sharesOverTime.length - 1]);

        // Withdraw all shares
        _pool.removeLiquidity(_onBehalfOf, shares);

        // Store the amount of tokens after the withdrawal
        uint256 amountAfter = token.balanceOf(address(this));

        // Calculate the amount of tokens to transfer
        uint256 amount = amountAfter - amountBefore;

        // Transfer the tokens to the user
        token.safeTransfer(_onBehalfOf, amount);

        emit Withdrawal(_onBehalfOf, address(_pool), msg.sender, amount);
    }   
}
