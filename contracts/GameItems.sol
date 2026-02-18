// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MegaRealms Items
 * @notice NFTs ERC-1155 representando itens do jogo
 * @dev ERC-1155 eh ideal para jogos: um contrato para todos os tipos de item
 *      Cada tokenId corresponde a um tipo de item (sword=1, plate=2, etc.)
 *      Itens stackaveis (pocoes) podem ter supply > 1
 */
contract GameItems is ERC1155, Ownable {
    // Mapeamento de nome do item para tokenId
    mapping(string => uint256) public itemIds;
    mapping(uint256 => string) public itemNames;
    mapping(address => bool) public minters;
    uint256 public nextTokenId = 1;

    // Metadata de cada item
    struct ItemMeta {
        string name;
        string itemType; // weapon, armor, potion, loot
        uint256 atk;
        uint256 def;
        uint256 heal;
        uint256 price;
        bool stackable;
    }
    mapping(uint256 => ItemMeta) public itemMeta;

    event ItemRegistered(uint256 indexed tokenId, string name);
    event ItemMinted(address indexed to, uint256 indexed tokenId, uint256 amount);

    constructor() ERC1155("https://megarealms.gg/api/items/{id}.json") Ownable(msg.sender) {
        minters[msg.sender] = true;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Nao autorizado");
        _;
    }

    function addMinter(address _minter) external onlyOwner {
        minters[_minter] = true;
    }

    /// @notice Registra um novo tipo de item no jogo
    function registerItem(
        string calldata name,
        string calldata itemType,
        uint256 atk,
        uint256 def,
        uint256 heal,
        uint256 price,
        bool stackable
    ) external onlyOwner returns (uint256) {
        uint256 id = nextTokenId++;
        itemIds[name] = id;
        itemNames[id] = name;
        itemMeta[id] = ItemMeta(name, itemType, atk, def, heal, price, stackable);
        emit ItemRegistered(id, name);
        return id;
    }

    /// @notice Minta um item para um jogador (drop de monstro, compra, etc.)
    function mint(address to, uint256 tokenId, uint256 amount) external onlyMinter {
        require(bytes(itemNames[tokenId]).length > 0, "Item nao registrado");
        _mint(to, tokenId, amount, "");
        emit ItemMinted(to, tokenId, amount);
    }

    /// @notice Minta multiplos itens de uma vez (loot bag)
    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external onlyMinter {
        _mintBatch(to, tokenIds, amounts, "");
    }

    /// @notice Queima item (usado, vendido, etc.)
    function burn(address from, uint256 tokenId, uint256 amount) external {
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "Nao autorizado");
        _burn(from, tokenId, amount);
    }

    /// @notice Retorna metadata de um item
    function getItemMeta(uint256 tokenId) external view returns (ItemMeta memory) {
        return itemMeta[tokenId];
    }
}
