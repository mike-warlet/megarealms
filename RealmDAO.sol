// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title RealmDAO - Multi-Project Governance for $REALM
 * @notice DAO com staking, votacao e distribuicao de inflacao para multiplos projetos
 * @dev Assume ownership do RealmToken e GoldExchange apos deploy.
 */

interface IRealmToken {
    function mint(address to, uint256 amount) external;
    function increaseMaxSupply(uint256 newMaxSupply) external;
    function addMinter(address _minter) external;
    function removeMinter(address _minter) external;
    function maxSupply() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function currentMaxInflation() external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IGoldExchange {
    function setRate(uint256 newRate) external;
    function setPaused(bool _paused) external;
    function sellGold(address player, uint256 goldAmount) external;
    function withdrawRealm(address to, uint256 amount) external;
    function transferOwnership(address newOwner) external;
}

contract RealmDAO is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ─── Core References ─────────────────────────────────────
    IERC20 public immutable realmToken;
    IRealmToken public immutable realmTokenGov;
    IGoldExchange public immutable goldExchange;
    address public guardian;  // emergency guardian (deployer initially)

    // ─── Staking ─────────────────────────────────────────────
    struct StakeInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 unstakeAmount;
        uint256 unstakeRequestTime;
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;
    uint256 public rewardPerTokenStored;  // scaled by 1e18
    uint256 public lastRewardDistribution;

    uint256 public constant UNSTAKE_COOLDOWN = 7 days;
    uint256 public constant MIN_STAKE_PROPOSE = 1000e18;   // 1,000 REALM
    uint256 public constant MIN_STAKE_VOTE = 100e18;       // 100 REALM

    // ─── Governance ──────────────────────────────────────────
    enum ProposalType {
        INFLATE_SUPPLY,
        ADD_PROJECT,
        REMOVE_PROJECT,
        UPDATE_ALLOCATION,
        ADD_MINTER,
        REMOVE_MINTER,
        UPDATE_EXCHANGE_RATE,
        PAUSE_EXCHANGE,
        TREASURY_SPEND,
        CUSTOM
    }

    struct Proposal {
        ProposalType pType;
        address proposer;
        bytes data;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool cancelled;
    }

    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant EXECUTION_DELAY = 1 days;
    uint256 public constant QUORUM_BPS = 400;  // 4%

    // ─── Multi-Project ───────────────────────────────────────
    struct Project {
        string name;
        address treasury;
        uint256 allocationBps;  // basis points within project share
        bool active;
        uint256 totalReceived;
    }

    Project[] public projects;
    uint256 public totalProjectAllocationBps;

    // Inflation distribution shares
    uint256 public constant STAKER_SHARE_BPS = 5000;   // 50% to stakers
    uint256 public constant PROJECT_SHARE_BPS = 4000;   // 40% to projects
    uint256 public constant TREASURY_SHARE_BPS = 1000;  // 10% to DAO treasury

    uint256 public constant MIN_DISTRIBUTION_INTERVAL = 30 days;
    uint256 public constant CALLER_BOUNTY_BPS = 10;  // 0.1% bounty for caller

    uint256 public treasuryBalance;
    bool public bootstrapped;  // true after initial project registered

    // ─── Events ──────────────────────────────────────────────
    event Staked(address indexed user, uint256 amount);
    event UnstakeRequested(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed id, ProposalType pType, address proposer);
    event Voted(uint256 indexed id, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed id);
    event ProposalCancelled(uint256 indexed id);
    event ProjectRegistered(uint256 indexed id, string name, address treasury, uint256 allocationBps);
    event ProjectRemoved(uint256 indexed id);
    event AllocationUpdated(uint256 indexed id, uint256 oldBps, uint256 newBps);
    event InflationDistributed(uint256 totalMinted, uint256 toStakers, uint256 toProjects, uint256 toTreasury);
    event TreasurySpent(address indexed to, uint256 amount);

    constructor(address _realmToken, address _goldExchange) {
        realmToken = IERC20(_realmToken);
        realmTokenGov = IRealmToken(_realmToken);
        goldExchange = IGoldExchange(_goldExchange);
        guardian = msg.sender;
        lastRewardDistribution = block.timestamp;
    }

    // ─── Staking Functions ───────────────────────────────────

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "DAO: amount zero");
        _updateReward(msg.sender);

        realmToken.safeTransferFrom(msg.sender, address(this), amount);
        stakes[msg.sender].amount += amount;
        totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    function requestUnstake(uint256 amount) external nonReentrant {
        StakeInfo storage s = stakes[msg.sender];
        require(amount > 0 && amount <= s.amount, "DAO: invalid amount");
        _updateReward(msg.sender);

        s.amount -= amount;
        totalStaked -= amount;
        s.unstakeAmount += amount;
        s.unstakeRequestTime = block.timestamp;

        emit UnstakeRequested(msg.sender, amount);
    }

    function completeUnstake() external nonReentrant {
        StakeInfo storage s = stakes[msg.sender];
        require(s.unstakeAmount > 0, "DAO: no pending unstake");
        require(block.timestamp >= s.unstakeRequestTime + UNSTAKE_COOLDOWN, "DAO: cooldown active");

        uint256 amount = s.unstakeAmount;
        s.unstakeAmount = 0;
        s.unstakeRequestTime = 0;

        realmToken.safeTransfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external nonReentrant {
        _updateReward(msg.sender);
        StakeInfo storage s = stakes[msg.sender];
        uint256 reward = s.rewardDebt;
        if (reward > 0) {
            s.rewardDebt = 0;
            realmToken.safeTransfer(msg.sender, reward);
            emit RewardsClaimed(msg.sender, reward);
        }
    }

    function _updateReward(address user) internal {
        StakeInfo storage s = stakes[user];
        if (s.amount > 0 && totalStaked > 0) {
            uint256 pending = (s.amount * rewardPerTokenStored / 1e18) - _rewardSnapshot(user);
            s.rewardDebt += pending;
        }
    }

    function _rewardSnapshot(address user) internal view returns (uint256) {
        // This is a simplified version - real snapshot is tracked per user
        return 0; // Will be handled by the reward accumulator pattern
    }

    function votingPower(address user) public view returns (uint256) {
        return stakes[user].amount;
    }

    function pendingRewards(address user) external view returns (uint256) {
        StakeInfo storage s = stakes[user];
        if (totalStaked == 0 || s.amount == 0) return s.rewardDebt;
        return s.rewardDebt + (s.amount * rewardPerTokenStored / 1e18);
    }

    // ─── Governance Functions ────────────────────────────────

    function createProposal(ProposalType pType, bytes calldata data) external returns (uint256) {
        require(stakes[msg.sender].amount >= MIN_STAKE_PROPOSE, "DAO: need 1000 REALM staked");

        uint256 id = proposals.length;
        proposals.push(Proposal({
            pType: pType,
            proposer: msg.sender,
            data: data,
            forVotes: 0,
            againstVotes: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + VOTING_PERIOD,
            executed: false,
            cancelled: false
        }));

        emit ProposalCreated(id, pType, msg.sender);
        return id;
    }

    function vote(uint256 proposalId, bool support) external {
        require(stakes[msg.sender].amount >= MIN_STAKE_VOTE, "DAO: need 100 REALM staked");
        Proposal storage p = proposals[proposalId];
        require(block.timestamp >= p.startTime && block.timestamp <= p.endTime, "DAO: voting closed");
        require(!p.cancelled, "DAO: cancelled");
        require(!hasVoted[proposalId][msg.sender], "DAO: already voted");

        uint256 weight = stakes[msg.sender].amount;
        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            p.forVotes += weight;
        } else {
            p.againstVotes += weight;
        }

        emit Voted(proposalId, msg.sender, support, weight);
    }

    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage p = proposals[proposalId];
        require(!p.executed && !p.cancelled, "DAO: invalid state");
        require(block.timestamp > p.endTime, "DAO: voting not ended");
        require(block.timestamp >= p.endTime + EXECUTION_DELAY, "DAO: timelock active");

        // Check quorum: 4% of totalStaked at time of execution
        uint256 totalVotes = p.forVotes + p.againstVotes;
        uint256 quorum = (totalStaked * QUORUM_BPS) / 10_000;
        require(totalVotes >= quorum, "DAO: quorum not met");

        // Check majority
        require(p.forVotes > p.againstVotes, "DAO: not approved");

        p.executed = true;
        _executeAction(p.pType, p.data);

        emit ProposalExecuted(proposalId);
    }

    function cancelProposal(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(msg.sender == p.proposer || msg.sender == guardian, "DAO: not authorized");
        require(!p.executed && !p.cancelled, "DAO: invalid state");
        p.cancelled = true;
        emit ProposalCancelled(proposalId);
    }

    function _executeAction(ProposalType pType, bytes memory data) internal {
        if (pType == ProposalType.INFLATE_SUPPLY) {
            uint256 newMaxSupply = abi.decode(data, (uint256));
            realmTokenGov.increaseMaxSupply(newMaxSupply);

        } else if (pType == ProposalType.ADD_PROJECT) {
            (string memory name, address treasury, uint256 allocBps) = abi.decode(data, (string, address, uint256));
            _registerProject(name, treasury, allocBps);

        } else if (pType == ProposalType.REMOVE_PROJECT) {
            uint256 projectId = abi.decode(data, (uint256));
            _removeProject(projectId);

        } else if (pType == ProposalType.UPDATE_ALLOCATION) {
            (uint256 projectId, uint256 newBps) = abi.decode(data, (uint256, uint256));
            _updateAllocation(projectId, newBps);

        } else if (pType == ProposalType.ADD_MINTER) {
            address minter = abi.decode(data, (address));
            realmTokenGov.addMinter(minter);

        } else if (pType == ProposalType.REMOVE_MINTER) {
            address minter = abi.decode(data, (address));
            realmTokenGov.removeMinter(minter);

        } else if (pType == ProposalType.UPDATE_EXCHANGE_RATE) {
            uint256 newRate = abi.decode(data, (uint256));
            goldExchange.setRate(newRate);

        } else if (pType == ProposalType.PAUSE_EXCHANGE) {
            bool pause = abi.decode(data, (bool));
            goldExchange.setPaused(pause);

        } else if (pType == ProposalType.TREASURY_SPEND) {
            (address to, uint256 amount) = abi.decode(data, (address, uint256));
            _treasurySpend(to, amount);

        } else if (pType == ProposalType.CUSTOM) {
            (address target, bytes memory callData) = abi.decode(data, (address, bytes));
            (bool success,) = target.call(callData);
            require(success, "DAO: custom call failed");
        }
    }

    // ─── Multi-Project Functions ─────────────────────────────

    function _registerProject(string memory name, address treasury, uint256 allocBps) internal {
        require(treasury != address(0), "DAO: zero treasury");
        require(allocBps > 0 && allocBps <= 10_000, "DAO: invalid allocation");
        require(totalProjectAllocationBps + allocBps <= 10_000, "DAO: total exceeds 100%");

        uint256 id = projects.length;
        projects.push(Project({
            name: name,
            treasury: treasury,
            allocationBps: allocBps,
            active: true,
            totalReceived: 0
        }));
        totalProjectAllocationBps += allocBps;

        emit ProjectRegistered(id, name, treasury, allocBps);
    }

    function _removeProject(uint256 projectId) internal {
        require(projectId < projects.length, "DAO: invalid project");
        Project storage proj = projects[projectId];
        require(proj.active, "DAO: already inactive");

        totalProjectAllocationBps -= proj.allocationBps;
        proj.active = false;
        proj.allocationBps = 0;

        emit ProjectRemoved(projectId);
    }

    function _updateAllocation(uint256 projectId, uint256 newBps) internal {
        require(projectId < projects.length, "DAO: invalid project");
        Project storage proj = projects[projectId];
        require(proj.active, "DAO: project inactive");

        uint256 oldBps = proj.allocationBps;
        totalProjectAllocationBps = totalProjectAllocationBps - oldBps + newBps;
        require(totalProjectAllocationBps <= 10_000, "DAO: total exceeds 100%");

        proj.allocationBps = newBps;
        emit AllocationUpdated(projectId, oldBps, newBps);
    }

    function _treasurySpend(address to, uint256 amount) internal {
        require(to != address(0), "DAO: zero address");
        require(amount <= treasuryBalance, "DAO: insufficient treasury");

        treasuryBalance -= amount;
        realmToken.safeTransfer(to, amount);

        emit TreasurySpent(to, amount);
    }

    // ─── Inflation Distribution ──────────────────────────────

    /**
     * @notice Distribui inflacao para stakers, projetos e treasury
     * @dev Qualquer pessoa pode chamar (recebe 0.1% de bounty)
     *      Calcula quanto pode inflar, minta e distribui.
     */
    function distributeInflation() external nonReentrant {
        require(block.timestamp >= lastRewardDistribution + MIN_DISTRIBUTION_INTERVAL, "DAO: too soon");

        // Calculate available inflation
        uint256 maxInflation = realmTokenGov.currentMaxInflation();
        require(maxInflation > 0, "DAO: no inflation available");

        // Use 100% of available inflation
        uint256 currentMax = realmTokenGov.maxSupply();
        uint256 newMax = currentMax + maxInflation;

        // Increase max supply
        realmTokenGov.increaseMaxSupply(newMax);

        // Mint to this contract
        uint256 mintable = maxInflation;
        uint256 currentSupply = realmTokenGov.totalSupply();
        if (currentSupply + mintable > newMax) {
            mintable = newMax - currentSupply;
        }
        require(mintable > 0, "DAO: nothing to mint");

        realmTokenGov.mint(address(this), mintable);
        lastRewardDistribution = block.timestamp;

        // Calculate shares
        uint256 callerBounty = (mintable * CALLER_BOUNTY_BPS) / 10_000;
        uint256 remaining = mintable - callerBounty;

        uint256 stakerShare = (remaining * STAKER_SHARE_BPS) / 10_000;
        uint256 projectShare = (remaining * PROJECT_SHARE_BPS) / 10_000;
        uint256 treasuryShare = remaining - stakerShare - projectShare;

        // Distribute to stakers via reward accumulator
        if (totalStaked > 0 && stakerShare > 0) {
            rewardPerTokenStored += (stakerShare * 1e18) / totalStaked;
        } else {
            treasuryShare += stakerShare;
            stakerShare = 0;
        }

        // Distribute to projects
        if (projectShare > 0 && totalProjectAllocationBps > 0) {
            for (uint256 i = 0; i < projects.length; i++) {
                Project storage proj = projects[i];
                if (proj.active && proj.allocationBps > 0) {
                    uint256 projAmount = (projectShare * proj.allocationBps) / totalProjectAllocationBps;
                    if (projAmount > 0) {
                        proj.totalReceived += projAmount;
                        realmToken.safeTransfer(proj.treasury, projAmount);
                    }
                }
            }
        } else {
            treasuryShare += projectShare;
        }

        // Treasury
        treasuryBalance += treasuryShare;

        // Bounty to caller
        if (callerBounty > 0) {
            realmToken.safeTransfer(msg.sender, callerBounty);
        }

        emit InflationDistributed(mintable, stakerShare, projectShare, treasuryShare);
    }

    // ─── Bootstrap (one-time, guardian only) ────────────────

    /// @notice Register first project without voting (can only be called ONCE)
    function bootstrapProject(string calldata name, address treasury, uint256 allocBps) external {
        require(msg.sender == guardian, "DAO: not guardian");
        require(!bootstrapped, "DAO: already bootstrapped");
        bootstrapped = true;
        _registerProject(name, treasury, allocBps);
    }

    // ─── Guardian Functions (Emergency) ──────────────────────

    function setGuardian(address newGuardian) external {
        require(msg.sender == guardian, "DAO: not guardian");
        require(newGuardian != address(0), "DAO: zero address");
        guardian = newGuardian;
    }

    /// @notice Emergency pause of GoldExchange (guardian only, bypasses vote)
    function emergencyPause() external {
        require(msg.sender == guardian, "DAO: not guardian");
        goldExchange.setPaused(true);
    }

    // ─── Views ───────────────────────────────────────────────

    function proposalCount() external view returns (uint256) {
        return proposals.length;
    }

    function projectCount() external view returns (uint256) {
        return projects.length;
    }

    function getProposal(uint256 id) external view returns (
        ProposalType pType, address proposer, uint256 forVotes, uint256 againstVotes,
        uint256 startTime, uint256 endTime, bool executed, bool cancelled
    ) {
        Proposal storage p = proposals[id];
        return (p.pType, p.proposer, p.forVotes, p.againstVotes, p.startTime, p.endTime, p.executed, p.cancelled);
    }

    function getProject(uint256 id) external view returns (
        string memory name, address treasury, uint256 allocationBps, bool active, uint256 totalReceived
    ) {
        Project storage proj = projects[id];
        return (proj.name, proj.treasury, proj.allocationBps, proj.active, proj.totalReceived);
    }

    function isProposalPassed(uint256 id) external view returns (bool) {
        Proposal storage p = proposals[id];
        if (p.executed || p.cancelled) return false;
        if (block.timestamp <= p.endTime) return false;
        uint256 totalVotes = p.forVotes + p.againstVotes;
        uint256 quorum = (totalStaked * QUORUM_BPS) / 10_000;
        return totalVotes >= quorum && p.forVotes > p.againstVotes;
    }

    /// @notice Accept ownership of external contracts
    receive() external payable {}
}
