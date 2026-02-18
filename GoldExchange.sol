// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title MegaRealms Gold Exchange
 * @notice Ponte entre $REALM (on-chain) e Gold (in-game)
 * @dev Jogador deposita REALM → recebe Gold no jogo (via evento).
 *      Game server escuta GoldPurchased e credita gold ao jogador.
 *      Para sacar gold → REALM, o server chama withdrawRealm.
 */
contract GoldExchange is Ownable {
    using SafeERC20 for IERC20;

    /// @notice Referencia ao token $REALM
    IERC20 public immutable realmToken;

    /// @notice Taxa de cambio: quantos gold por 1 REALM (em wei, 1e18)
    /// @dev Default: 1000 gold por 1 REALM inteiro
    uint256 public goldPerRealm;

    /// @notice Pausa de emergencia
    bool public paused;

    /// @notice Total de REALM depositados (compra de gold)
    uint256 public totalDeposited;

    /// @notice Total de REALM sacados (venda de gold)
    uint256 public totalWithdrawn;

    event GoldPurchased(
        address indexed player,
        uint256 realmAmount,
        uint256 goldAmount
    );

    event GoldSold(
        address indexed player,
        uint256 realmAmount,
        uint256 goldAmount
    );

    event RateUpdated(uint256 oldRate, uint256 newRate);
    event Paused(bool isPaused);

    /**
     * @param _realmToken Endereco do contrato RealmToken
     * @param _goldPerRealm Gold recebido por 1 REALM inteiro (ex: 1000)
     */
    constructor(address _realmToken, uint256 _goldPerRealm) Ownable(msg.sender) {
        require(_realmToken != address(0), "GoldExchange: token zero");
        require(_goldPerRealm > 0, "GoldExchange: rate zero");
        realmToken = IERC20(_realmToken);
        goldPerRealm = _goldPerRealm;
    }

    modifier whenNotPaused() {
        require(!paused, "GoldExchange: pausado");
        _;
    }

    // ─── Comprar Gold (depositar REALM) ────────────────────────

    /**
     * @notice Jogador deposita REALM para receber Gold no jogo
     * @param realmAmount Quantidade de REALM (em wei, com 18 decimais)
     * @dev O game server escuta o evento GoldPurchased e credita o gold.
     *      Jogador precisa aprovar este contrato antes (approve).
     */
    function buyGold(uint256 realmAmount) external whenNotPaused {
        require(realmAmount > 0, "GoldExchange: amount zero");

        // Calcula gold: realmAmount (wei) * goldPerRealm / 1e18
        uint256 goldAmount = (realmAmount * goldPerRealm) / 1e18;
        require(goldAmount > 0, "GoldExchange: gold seria zero");

        // Transfere REALM do jogador para este contrato
        realmToken.safeTransferFrom(msg.sender, address(this), realmAmount);
        totalDeposited += realmAmount;

        emit GoldPurchased(msg.sender, realmAmount, goldAmount);
    }

    // ─── Vender Gold (sacar REALM) ─────────────────────────────

    /**
     * @notice Game server envia REALM para jogador que vendeu gold
     * @param player Endereco do jogador
     * @param goldAmount Quantidade de gold vendido no jogo
     * @dev Chamado apenas pelo owner (game server backend).
     *      O server valida que o jogador realmente tinha o gold.
     */
    function sellGold(address player, uint256 goldAmount) external onlyOwner whenNotPaused {
        require(player != address(0), "GoldExchange: player zero");
        require(goldAmount > 0, "GoldExchange: gold zero");

        // Calcula REALM: goldAmount * 1e18 / goldPerRealm
        uint256 realmAmount = (goldAmount * 1e18) / goldPerRealm;
        require(realmAmount > 0, "GoldExchange: realm seria zero");
        require(realmToken.balanceOf(address(this)) >= realmAmount, "GoldExchange: saldo insuficiente");

        realmToken.safeTransfer(player, realmAmount);
        totalWithdrawn += realmAmount;

        emit GoldSold(player, realmAmount, goldAmount);
    }

    // ─── Admin ─────────────────────────────────────────────────

    /// @notice Atualiza a taxa de cambio
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "GoldExchange: rate zero");
        uint256 oldRate = goldPerRealm;
        goldPerRealm = newRate;
        emit RateUpdated(oldRate, newRate);
    }

    /// @notice Pausa/despausa o exchange
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    /// @notice Retira REALM do contrato (emergencia ou rebalanceamento)
    function withdrawRealm(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "GoldExchange: to zero");
        realmToken.safeTransfer(to, amount);
    }

    // ─── Views ─────────────────────────────────────────────────

    /// @notice Saldo de REALM no contrato (pool de liquidez)
    function realmBalance() external view returns (uint256) {
        return realmToken.balanceOf(address(this));
    }

    /// @notice Calcula quanto gold o jogador receberia por X REALM
    function previewBuyGold(uint256 realmAmount) external view returns (uint256) {
        return (realmAmount * goldPerRealm) / 1e18;
    }

    /// @notice Calcula quanto REALM o jogador receberia por X gold
    function previewSellGold(uint256 goldAmount) external view returns (uint256) {
        return (goldAmount * 1e18) / goldPerRealm;
    }
}
