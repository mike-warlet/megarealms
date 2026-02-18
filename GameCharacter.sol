// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MegaRealms Character
 * @notice NFT ERC-721 representando o personagem do jogador
 * @dev Cada jogador minta 1 NFT que armazena seus stats on-chain
 *      Na Base L2, salvar estado e barato e rapido (2s blocks)
 */
contract GameCharacter is ERC721, Ownable {
    uint256 public nextCharId = 1;

    struct CharacterData {
        string name;
        string vocation; // knight, paladin, sorcerer, druid
        uint256 level;
        uint256 xp;
        uint256 hp;
        uint256 maxHp;
        uint256 mp;
        uint256 maxMp;
        uint256 atk;
        uint256 def;
        uint256 gold;
        uint256 createdAt;
        uint256 lastSaved;
    }

    mapping(uint256 => CharacterData) public characters;
    mapping(address => uint256) public playerCharacter; // 1 char per wallet

    event CharacterMinted(address indexed player, uint256 indexed charId, string name, string vocation);
    event CharacterSaved(uint256 indexed charId, uint256 level, uint256 xp);

    constructor() ERC721("MegaRealms Character", "MRCHAR") Ownable(msg.sender) {}

    /// @notice Cria um personagem (1 por wallet)
    function mintCharacter(string calldata name, string calldata vocation) external returns (uint256) {
        require(playerCharacter[msg.sender] == 0, "Ja possui um personagem");
        require(bytes(name).length > 0 && bytes(name).length <= 16, "Nome invalido");

        uint256 charId = nextCharId++;

        // Stats iniciais baseados na vocacao
        (uint256 hp, uint256 mp, uint256 atk, uint256 def) = _getBaseStats(vocation);

        characters[charId] = CharacterData({
            name: name,
            vocation: vocation,
            level: 1,
            xp: 0,
            hp: hp,
            maxHp: hp,
            mp: mp,
            maxMp: mp,
            atk: atk,
            def: def,
            gold: 100,
            createdAt: block.timestamp,
            lastSaved: block.timestamp
        });

        playerCharacter[msg.sender] = charId;
        _mint(msg.sender, charId);

        emit CharacterMinted(msg.sender, charId, name, vocation);
        return charId;
    }

    /// @notice Salva o progresso do personagem on-chain
    function saveProgress(
        uint256 charId,
        uint256 level,
        uint256 xp,
        uint256 hp,
        uint256 maxHp,
        uint256 mp,
        uint256 maxMp,
        uint256 atk,
        uint256 def,
        uint256 gold
    ) external {
        require(ownerOf(charId) == msg.sender, "Nao eh o dono");
        CharacterData storage c = characters[charId];
        c.level = level;
        c.xp = xp;
        c.hp = hp;
        c.maxHp = maxHp;
        c.mp = mp;
        c.maxMp = maxMp;
        c.atk = atk;
        c.def = def;
        c.gold = gold;
        c.lastSaved = block.timestamp;

        emit CharacterSaved(charId, level, xp);
    }

    /// @notice Retorna os dados completos do personagem
    function getCharacter(uint256 charId) external view returns (CharacterData memory) {
        return characters[charId];
    }

    /// @notice Retorna o charId do jogador
    function getPlayerCharId(address player) external view returns (uint256) {
        return playerCharacter[player];
    }

    /// @notice Stats iniciais por vocacao
    function _getBaseStats(string calldata vocation) internal pure returns (uint256 hp, uint256 mp, uint256 atk, uint256 def) {
        bytes32 voc = keccak256(bytes(vocation));
        if (voc == keccak256("knight")) return (185, 35, 12, 8);
        if (voc == keccak256("paladin")) return (150, 60, 10, 6);
        if (voc == keccak256("sorcerer")) return (110, 100, 6, 3);
        if (voc == keccak256("druid")) return (130, 85, 7, 4);
        revert("Vocacao invalida");
    }
}
