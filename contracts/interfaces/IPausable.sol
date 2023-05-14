// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IPausable {
    /**
     * @notice Pauses the contract. Only callable by the pool controller
     */
    function pause () external;

    /**
     * @notice Unpauses the contract. Only callable by the pool controller.
     */
    function unpause () external;
}