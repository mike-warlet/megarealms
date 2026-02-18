// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MegaRealms Items v2
 * @notice NFTs ERC-1155 representando itens do jogo
 * @dev v2: Batch limits, minter events, nome unico, minter cap, validacoes.
 */
contract GameItems is ERC1155, Ownable {
    mapping(string => uint256) public itemIds;
    mapping(uint256 => string) public itemNames;
    mapping(address => bool) public minters;
    uint256 public nextTokenId = 1;
    uint256 public minterCount;

    uint256 public constant MAX_MINTERS = 5;
    uint256 public constant MAX_BATCH_SIZE = 50;
    uint256 public constant MAX_MINT_AMOUNT = 10_000;

    struct ItemMeta {
        string name;
        string itemType;
        uint256 atk;
        uint256 def;
        uint256 heal;
        uint256 price;
        bool stackable;
    }
    mapping(uint256 => ItemMeta) public itemMeta;

    event ItemRegistered(uint256 indexed tokenId, string name);
    event ItemMinted(address indexed to, uint256 indexed tokenId, uint256 amount);
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);

    constructor() ERC1155("https://megarealms.io/api/items/{id}.json") Ownable(msg.sender) {
        minters[msg.sender] = true;
        minterCount = 1;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Nao autorizado");
        _;
    }

    function addMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "Endereco zero");
        require(!minters[_minter], "Ja eh minter");
        require(minterCount < MAX_MINTERS, "Limite de minters");
        minters[_minter] = true;
        minterCount++;
        emit MinterAdded(_minter);
    }

    function removeMinter(address _minter) external onlyOwner {
        require(minters[_minter], "Nao eh minter");
        minters[_minter] = false;
        minterCount--;
        emit MinterRemoved(_minter);
    }

    /// @notice Registra um novo tipo de item (nome deve ser unico)
    function registerItem(
        string calldata name,
        string calldata itemType,
        uint256 atk,
        uint256 def,
        uint256 heal,
        uint256 price,
        bool stackable
    ) external onlyOwner returns (uint256) {
        require(bytes(name).length > 0 && bytes(name).length <= 32, "Nome invalido");
        require(itemIds[name] == 0, "Nome ja registrado");
        require(atk <= 1000 && def <= 1000 && heal <= 10000, "Stats excedidos");

        uint256 id = nextTokenId++;
        itemIds[name] = id;
        itemNames[id] = name;
        itemMeta[id] = ItemMeta(name, itemType, atk, def, heal, price, stackable);
        emit ItemRegistered(id, name);
        return id;
    }

    /// @notice Minta um item para um jogador (max 10k por vez)
    function mint(address to, uint256 tokenId, uint256 amount) external onlyMinter {
        require(bytes(itemNames[tokenId]).length > 0, "Item nao registrado");
        require(amount > 0 && amount <= MAX_MINT_AMOUNT, "Quantidade invalida");
        _mint(to, tokenId, amount, "");
        emit ItemMinted(to, tokenId, amount);
    }

    /// @notice Minta multiplos itens (max 50 por batch, max 10k cada)
    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external onlyMinter {
        require(tokenIds.length == amounts.length, "Arrays diferentes");
        require(tokenIds.length > 0 && tokenIds.length <= MAX_BATCH_SIZE, "Batch excede limite");
        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] > 0 && amounts[i] <= MAX_MINT_AMOUNT, "Quantidade invalida");
            require(bytes(itemNames[tokenIds[i]]).length > 0, "Item nao registrado");
        }
        _mintBatch(to, tokenIds, amounts, "");
    }

    /// @notice Queima item (apenas pelo dono)
    function burn(address from, uint256 tokenId, uint256 amount) external {
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "Nao autorizado");
        _burn(from, tokenId, amount);
    }

    function getItemMeta(uint256 tokenId) external view returns (ItemMeta memory) {
        return itemMeta[tokenId];
    }
}
