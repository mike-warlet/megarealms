// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MegaRealms Gold Exchange v2
 * @notice Ponte entre $REALM (on-chain) e Gold (in-game)
 * @dev v2: ReentrancyGuard, rate change limits, withdraw limits, max pause, cooldowns.
 */
contract GoldExchange is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Referencia ao token $REALM
    IERC20 public immutable realmToken;

    /// @notice Taxa de cambio: quantos gold por 1 REALM (em wei, 1e18)
    uint256 public goldPerRealm;

    /// @notice Pausa de emergencia
    bool public paused;
    uint256 public pausedAt;

    /// @notice Max duracao de pausa: 7 dias (depois auto-resume)
    uint256 public constant MAX_PAUSE_DURATION = 7 days;

    /// @notice Limite de mudanca de rate: max 10% por mudanca
    uint256 public constant MAX_RATE_CHANGE_BPS = 1000; // 10%

    /// @notice Intervalo minimo entre mudancas de rate: 24h
    uint256 public constant MIN_RATE_CHANGE_INTERVAL = 1 days;
    uint256 public lastRateChangeTime;

    /// @notice Limite de withdraw: max 10% do saldo por dia
    uint256 public constant MAX_WITHDRAW_BPS = 1000; // 10%
    uint256 public dailyWithdrawn;
    uint256 public lastWithdrawDay;

    /// @notice Limite minimo de compra
    uint256 public constant MIN_BUY_AMOUNT = 1e15; // 0.001 REALM

    /// @notice Total de REALM depositados/sacados
    uint256 public totalDeposited;
    uint256 public totalWithdrawn;

    event GoldPurchased(address indexed player, uint256 realmAmount, uint256 goldAmount);
    event GoldSold(address indexed player, uint256 realmAmount, uint256 goldAmount);
    event RateUpdated(uint256 oldRate, uint256 newRate);
    event Paused(bool isPaused, uint256 timestamp);
    event EmergencyWithdraw(address indexed to, uint256 amount);

    constructor(address _realmToken, uint256 _goldPerRealm) Ownable(msg.sender) {
        require(_realmToken != address(0), "GoldExchange: token zero");
        require(_goldPerRealm > 0, "GoldExchange: rate zero");
        realmToken = IERC20(_realmToken);
        goldPerRealm = _goldPerRealm;
        lastRateChangeTime = block.timestamp;
    }

    modifier whenNotPaused() {
        // Auto-resume apos MAX_PAUSE_DURATION
        if (paused && block.timestamp >= pausedAt + MAX_PAUSE_DURATION) {
            paused = false;
        }
        require(!paused, "GoldExchange: pausado");
        _;
    }

    // ─── Comprar Gold (depositar REALM) ────────────────────────

    /// @notice Jogador deposita REALM para receber Gold no jogo
    function buyGold(uint256 realmAmount) external nonReentrant whenNotPaused {
        require(realmAmount >= MIN_BUY_AMOUNT, "GoldExchange: abaixo do minimo");

        uint256 goldAmount = (realmAmount * goldPerRealm) / 1e18;
        require(goldAmount > 0, "GoldExchange: gold seria zero");

        realmToken.safeTransferFrom(msg.sender, address(this), realmAmount);
        totalDeposited += realmAmount;

        emit GoldPurchased(msg.sender, realmAmount, goldAmount);
    }

    // ─── Vender Gold (sacar REALM) ─────────────────────────────

    /// @notice Game server envia REALM para jogador que vendeu gold
    function sellGold(address player, uint256 goldAmount) external onlyOwner nonReentrant whenNotPaused {
        require(player != address(0), "GoldExchange: player zero");
        require(goldAmount > 0, "GoldExchange: gold zero");

        uint256 realmAmount = (goldAmount * 1e18) / goldPerRealm;
        require(realmAmount > 0, "GoldExchange: realm seria zero");
        require(realmToken.balanceOf(address(this)) >= realmAmount, "GoldExchange: saldo insuficiente");

        realmToken.safeTransfer(player, realmAmount);
        totalWithdrawn += realmAmount;

        emit GoldSold(player, realmAmount, goldAmount);
    }

    // ─── Admin ─────────────────────────────────────────────────

    /// @notice Atualiza a taxa de cambio (max 10% por mudanca, min 24h entre mudancas)
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "GoldExchange: rate zero");
        require(block.timestamp >= lastRateChangeTime + MIN_RATE_CHANGE_INTERVAL,
            "GoldExchange: minimo 24h entre mudancas");

        // Limitar mudanca a max 10%
        uint256 oldRate = goldPerRealm;
        uint256 diff = newRate > oldRate ? newRate - oldRate : oldRate - newRate;
        uint256 maxChange = (oldRate * MAX_RATE_CHANGE_BPS) / 10_000;
        require(diff <= maxChange, "GoldExchange: mudanca excede 10%");

        goldPerRealm = newRate;
        lastRateChangeTime = block.timestamp;
        emit RateUpdated(oldRate, newRate);
    }

    /// @notice Pausa/despausa o exchange (max 7 dias de pausa)
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        if (_paused) {
            pausedAt = block.timestamp;
        }
        emit Paused(_paused, block.timestamp);
    }

    /// @notice Retira REALM do contrato (max 10% do saldo por dia)
    function withdrawRealm(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "GoldExchange: to zero");

        // Rate limiting: max 10% do saldo por dia
        uint256 today = block.timestamp / 1 days;
        if (lastWithdrawDay != today) {
            dailyWithdrawn = 0;
            lastWithdrawDay = today;
        }

        uint256 balance = realmToken.balanceOf(address(this));
        uint256 maxDaily = (balance * MAX_WITHDRAW_BPS) / 10_000;
        dailyWithdrawn += amount;
        require(dailyWithdrawn <= maxDaily, "GoldExchange: excede limite diario de withdraw (10%)");

        realmToken.safeTransfer(to, amount);
        emit EmergencyWithdraw(to, amount);
    }

    // ─── Views ─────────────────────────────────────────────────

    function realmBalance() external view returns (uint256) {
        return realmToken.balanceOf(address(this));
    }

    function previewBuyGold(uint256 realmAmount) external view returns (uint256) {
        return (realmAmount * goldPerRealm) / 1e18;
    }

    function previewSellGold(uint256 goldAmount) external view returns (uint256) {
        return (goldAmount * 1e18) / goldPerRealm;
    }

    /// @notice Retorna se a pausa expirou (auto-resume)
    function isPaused() external view returns (bool) {
        if (paused && block.timestamp >= pausedAt + MAX_PAUSE_DURATION) return false;
        return paused;
    }
}
