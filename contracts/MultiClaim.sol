// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IBasePool} from "./interfaces/IBasePool.sol";

contract MultiClaim {
    using SafeERC20 for IERC20;

    function claimMultiple(
        IBasePool pool,
        address _onBehalfOf,
        uint256[] calldata _loanIdxs,
        bool[] calldata _isReinvested,
        uint256 _deadline
    ) external {
        require(
            _loanIdxs.length == _isReinvested.length,
            "MultiClaim: inconsistent lengths"
        );
        (IERC20 loanCcyToken, IERC20 collCcyToken, , , , , , , ) = pool.getPoolInfo();

        uint256 loanCcyBalanceBefore = loanCcyToken.balanceOf(_onBehalfOf);
        uint256 collCcyBalanceBefore = collCcyToken.balanceOf(_onBehalfOf);
        
        for (uint256 i = 0; i < _loanIdxs.length; i++) {
            uint256[] memory indexArray = new uint256[](1);
            indexArray[0] = _loanIdxs[i];
            pool.claim(
                _onBehalfOf,
                indexArray,
                _isReinvested[i],
                _deadline
            );
        }

        // Transfer the loan currency to the user
        uint256 loanCcyBalanceAfter = loanCcyToken.balanceOf(_onBehalfOf);
        uint256 loanCcyBalanceDiff = loanCcyBalanceAfter - loanCcyBalanceBefore;
        if (loanCcyBalanceDiff > 0) {
            loanCcyToken.safeTransfer(_onBehalfOf, loanCcyBalanceDiff);
        }

        // Transfer the collateral currency to the user
        uint256 collCcyBalanceAfter = collCcyToken.balanceOf(_onBehalfOf);
        uint256 collCcyBalanceDiff = collCcyBalanceAfter - collCcyBalanceBefore;
        if (collCcyBalanceDiff > 0) {
            collCcyToken.safeTransfer(_onBehalfOf, collCcyBalanceDiff);
        }
    }
}