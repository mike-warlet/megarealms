// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MegaRealms Gold (MGOLD)
 * @notice Token ERC-20 que representa o ouro do jogo MegaRealms
 * @dev Deploy na Base L2 (Coinbase) para transacoes rapidas e baixo custo
 */
contract GameGold is ERC20, Ownable {
    // Enderecos autorizados a mintar (game server, contracts)
    mapping(address => bool) public minters;

    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);

    constructor() ERC20("MegaRealms Gold", "MGOLD") Ownable(msg.sender) {
        minters[msg.sender] = true;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Nao autorizado a mintar");
        _;
    }

    /// @notice Adiciona um endereco como minter autorizado
    function addMinter(address _minter) external onlyOwner {
        minters[_minter] = true;
        emit MinterAdded(_minter);
    }

    /// @notice Remove um minter autorizado
    function removeMinter(address _minter) external onlyOwner {
        minters[_minter] = false;
        emit MinterRemoved(_minter);
    }

    /// @notice Minta gold para um jogador (chamado pelo game contract)
    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    /// @notice Queima gold (quando jogador compra item no NPC)
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// @notice Decimals = 0 (gold eh inteiro, como no Tibia)
    function decimals() public pure override returns (uint8) {
        return 0;
    }
}
