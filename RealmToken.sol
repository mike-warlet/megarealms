// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Realm Token ($REALM) v2
 * @notice Token ERC-20 do ecossistema MegaRealms
 * @dev Deploy na Base L2 (Coinbase). Supply com cap + inflacao controlada para staking/DAO.
 *      v2: Corrigido limite de inflacao, minter limits, mint event, validacoes.
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

    /// @notice Intervalo minimo entre inflacoes: 30 dias
    uint256 public constant MIN_INFLATION_INTERVAL = 30 days;

    /// @notice Maximo de minters permitidos
    uint256 public constant MAX_MINTERS = 10;

    /// @notice Limite diario de mint por minter (tokens)
    uint256 public constant DAILY_MINT_LIMIT = 1_000_000 * 1e18; // 1M REALM/dia

    /// @notice Enderecos autorizados a mintar
    mapping(address => bool) public minters;

    /// @notice Controle de mint diario por minter
    mapping(address => uint256) public minterDailyMinted;
    mapping(address => uint256) public minterLastMintDay;

    /// @notice Contador de minters ativos
    uint256 public minterCount;

    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
    event MaxSupplyIncreased(uint256 oldMax, uint256 newMax);
    event TokensMinted(address indexed minter, address indexed to, uint256 amount);

    /**
     * @notice Deploy do token com mint inicial para treasury
     * @dev maxSupply = 1 bilhao, mint inicial = 100 milhoes para deployer
     */
    constructor() ERC20("Realm Token", "REALM") Ownable(msg.sender) {
        maxSupply = 1_000_000_000 * 1e18;          // 1B REALM
        lastInflationTime = block.timestamp;
        minters[msg.sender] = true;
        minterCount = 1;

        // Mint inicial: 100M para treasury (deployer)
        _mint(msg.sender, 100_000_000 * 1e18);
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "RealmToken: nao autorizado a mintar");
        _;
    }

    // ─── Minter Management ─────────────────────────────────────

    /// @notice Adiciona um endereco como minter autorizado (max 10)
    function addMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "RealmToken: endereco zero");
        require(!minters[_minter], "RealmToken: ja eh minter");
        require(minterCount < MAX_MINTERS, "RealmToken: limite de minters atingido");
        minters[_minter] = true;
        minterCount++;
        emit MinterAdded(_minter);
    }

    /// @notice Remove um minter autorizado
    function removeMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "RealmToken: endereco zero");
        require(minters[_minter], "RealmToken: nao eh minter");
        minters[_minter] = false;
        minterCount--;
        emit MinterRemoved(_minter);
    }

    // ─── Minting ───────────────────────────────────────────────

    /// @notice Minta tokens para um endereco (respeitando maxSupply + limite diario)
    function mint(address to, uint256 amount) external onlyMinter {
        require(to != address(0), "RealmToken: to zero");
        require(totalSupply() + amount <= maxSupply, "RealmToken: excede maxSupply");

        // Rate limiting: max 1M REALM por minter por dia
        uint256 today = block.timestamp / 1 days;
        if (minterLastMintDay[msg.sender] != today) {
            minterDailyMinted[msg.sender] = 0;
            minterLastMintDay[msg.sender] = today;
        }
        minterDailyMinted[msg.sender] += amount;
        require(minterDailyMinted[msg.sender] <= DAILY_MINT_LIMIT, "RealmToken: limite diario excedido");

        _mint(to, amount);
        emit TokensMinted(msg.sender, to, amount);
    }

    // ─── Inflacao Controlada ───────────────────────────────────

    /**
     * @notice Aumenta o maxSupply (inflacao controlada para staking/DAO)
     * @param newMaxSupply Novo valor de maxSupply
     * @dev Maximo de 5% ao ano, proporcional ao tempo desde ultima inflacao.
     *      Intervalo minimo de 30 dias entre inflacoes.
     */
    function increaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply > maxSupply, "RealmToken: novo max deve ser maior");

        // Intervalo minimo de 30 dias
        uint256 elapsed = block.timestamp - lastInflationTime;
        require(elapsed >= MIN_INFLATION_INTERVAL, "RealmToken: minimo 30 dias entre inflacoes");

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
        if (elapsed < MIN_INFLATION_INTERVAL) return 0;
        return (maxSupply * MAX_INFLATION_BPS * elapsed) / (10_000 * ONE_YEAR);
    }

    /// @notice Retorna quanto um minter ainda pode mintar hoje
    function dailyMintRemaining(address _minter) external view returns (uint256) {
        uint256 today = block.timestamp / 1 days;
        if (minterLastMintDay[_minter] != today) return DAILY_MINT_LIMIT;
        if (minterDailyMinted[_minter] >= DAILY_MINT_LIMIT) return 0;
        return DAILY_MINT_LIMIT - minterDailyMinted[_minter];
    }
}
