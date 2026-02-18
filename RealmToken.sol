// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Realm Token ($REALM)
 * @notice Token ERC-20 do ecossistema MegaRealms
 * @dev Deploy na Base L2 (Coinbase). Supply com cap + inflacao controlada para staking/DAO.
 */
contract RealmToken is ERC20, ERC20Burnable, Ownable {

    /// @notice Supply maximo atual (pode ser aumentado via inflacao controlada)
    uint256 public maxSupply;

    /// @notice Timestamp da ultima vez que o maxSupply foi aumentado
    uint256 public lastInflationTime;

    /// @notice Taxa maxima de inflacao: 5% ao ano (500 basis points)
    uint256 public constant MAX_INFLATION_BPS = 500;

    /// @notice 1 ano em segundos
    uint256 public constant ONE_YEAR = 365 days;

    /// @notice Enderecos autorizados a mintar (game server, exchange contract)
    mapping(address => bool) public minters;

    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
    event MaxSupplyIncreased(uint256 oldMax, uint256 newMax);

    /**
     * @notice Deploy do token com mint inicial para treasury
     * @dev maxSupply = 1 bilhao, mint inicial = 100 milhoes para deployer
     */
    constructor() ERC20("Realm Token", "REALM") Ownable(msg.sender) {
        maxSupply = 1_000_000_000 * 1e18;          // 1B REALM
        lastInflationTime = block.timestamp;
        minters[msg.sender] = true;

        // Mint inicial: 100M para treasury (deployer)
        _mint(msg.sender, 100_000_000 * 1e18);
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "RealmToken: nao autorizado a mintar");
        _;
    }

    // ─── Minter Management ─────────────────────────────────────

    /// @notice Adiciona um endereco como minter autorizado
    function addMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "RealmToken: endereco zero");
        minters[_minter] = true;
        emit MinterAdded(_minter);
    }

    /// @notice Remove um minter autorizado
    function removeMinter(address _minter) external onlyOwner {
        minters[_minter] = false;
        emit MinterRemoved(_minter);
    }

    // ─── Minting ───────────────────────────────────────────────

    /// @notice Minta tokens para um endereco (respeitando o maxSupply)
    function mint(address to, uint256 amount) external onlyMinter {
        require(totalSupply() + amount <= maxSupply, "RealmToken: excede maxSupply");
        _mint(to, amount);
    }

    // ─── Inflacao Controlada ───────────────────────────────────

    /**
     * @notice Aumenta o maxSupply (inflacao controlada para staking/DAO)
     * @param newMaxSupply Novo valor de maxSupply
     * @dev Maximo de 5% ao ano, proporcional ao tempo desde ultima inflacao.
     *      Exemplo: se passou 6 meses, pode aumentar ate 2.5%.
     */
    function increaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply > maxSupply, "RealmToken: novo max deve ser maior");

        // Calcula inflacao maxima permitida proporcional ao tempo
        uint256 elapsed = block.timestamp - lastInflationTime;
        require(elapsed > 0, "RealmToken: muito cedo para inflacao");

        // maxIncrease = maxSupply * 5% * (elapsed / 1 year)
        uint256 maxIncrease = (maxSupply * MAX_INFLATION_BPS * elapsed) / (10_000 * ONE_YEAR);
        uint256 requestedIncrease = newMaxSupply - maxSupply;
        require(requestedIncrease <= maxIncrease, "RealmToken: inflacao excede 5% anual");

        uint256 oldMax = maxSupply;
        maxSupply = newMaxSupply;
        lastInflationTime = block.timestamp;

        emit MaxSupplyIncreased(oldMax, newMaxSupply);
    }

    // ─── Views ─────────────────────────────────────────────────

    /// @notice Retorna quanto ainda pode ser mintado
    function mintableSupply() external view returns (uint256) {
        return maxSupply - totalSupply();
    }

    /// @notice Retorna a inflacao maxima permitida agora (em tokens)
    function currentMaxInflation() external view returns (uint256) {
        uint256 elapsed = block.timestamp - lastInflationTime;
        if (elapsed == 0) return 0;
        return (maxSupply * MAX_INFLATION_BPS * elapsed) / (10_000 * ONE_YEAR);
    }
}
