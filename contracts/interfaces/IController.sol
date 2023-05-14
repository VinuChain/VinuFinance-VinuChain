// SPDX-License-Identifier: GPL-3.0
pragma soliditypp ^0.8.0;

import "./IPausable.solpp";

interface IController {
    enum Action{
        PAUSE,
        UNPAUSE,
        WHITELIST,
        DEWHITELIST
    }

    event ProposalCreated(
        uint256 proposalIdx,
        address indexed creator,
        IPausable indexed target,
        Action action,
        uint256 deadline
    );

    event Voted(
        uint256 indexed proposalIdx,
        address indexed voter,
        uint256 votes,
        uint256 newTotalVotes
    );

    event Cancelled(
        uint256 indexed proposalIdx,
        address indexed voter,
        uint256 votes,
        uint256 newTotalVotes
    );

    event Executed(
        uint256 indexed proposalIdx,
        uint256 totalVotes,
        uint256 voteTokenTotalSupply
    );

    event DepositedVoteToken(
        address indexed account,
        uint256 amount,
        uint256 newBalance,
        uint256 newTotalSupply,
        uint256 subTimestamp
    );

    event WithdrawnVoteToken(
        address indexed account,
        uint256 amount,
        uint256 newBalance,
        uint256 newTotalSupply,
        uint256 subTimestamp
    );

    event TokenSnapshotPerformed(
        vitetoken indexed tokenId,
        uint256 tokenSnapshotIdx,
        uint256 voteTokenTotalSupply,
        uint256 collectedRevenue,
        uint256 subTimestamp
    );

    event TokenClaimed(
        vitetoken indexed tokenId,
        address indexed account,
        uint256 indexed tokenSnapshotIdx,
        uint256 accountSnapshotIdx,
        uint256 amount,
        uint256 totalClaimedRevenue
    );

    event VetoPowerTransfer(
        address oldHolder,
        address newHolder
    );

    event VetoHolderApproval(
        uint256 indexed proposalIdx,
        bool approved
    );

    event Reward(
        address account,
        uint128 liquidity,
        uint32 duration,
        uint96 rewardCoefficient,
        uint256 amount
    );

    struct Proposal {
        // Address of the target contract
        IPausable target;
        // Action to be executed
        Action action;
        // Total votes for this proposal
        uint256 totalVotes;
        // Veto holder approval
        // It is not a boolean because the veto holder might change
        address vetoApprover;
        // Number of votes by address
        mapping(address => uint256) votesByAddress;
        // Whether the proposal has been executed
        bool executed;
        // Deadline of the proposal
        uint256 deadline;
    }

    struct TokenSnapshot {
        // Total deposited tokens at the time of the snapshot
        uint256 voteTokenTotalSupply;
        // Total revenue of the given token collected at the time of the snapshot
        uint256 collectedRevenue;
        // Total revenue that has already been claimed
        uint256 claimedRevenue;
        // Timestamp of the snapshot
        uint256 timestamp;
        // Sub-timestamp of the snapshot
        uint256 subTimestamp;
        // Whether a given account has already claimed revenue for this snapshot
        mapping(address => bool) claimed;
    }

    struct AccountSnapshot {
        // Balance of the account at the time of the snapshot
        uint256 voteTokenBalance;
        // Timestamp of the snapshot
        uint256 timestamp;
        // Sub-timestamp of the snapshot
        uint256 subTimestamp;
    }

    /**
     * @notice Function called by pool contracts to deposit
     * controller fees
     */
    function depositRevenue () payable external;

    /**
     * @notice Requests distributing the vote token as reward
     *
     * @dev Can only be called by whitelisted pools
     * @dev _requestIdx is used to prevent duplicated requests
     *
     * @param _account Account to distribute the vote token to
     * @param _liquidity Liquidity of the awardee
     * @param _duration Duration of the deposit by the awardee
     * @param _rewardCoefficient Reward coefficient of the awarding pool
     * @param _requestIdx Index of the request
     */
    function requestTokenDistribution(address _account, uint128 _liquidity, uint32 _duration, uint96 _rewardCoefficient, uint256 _requestIdx) external;
}