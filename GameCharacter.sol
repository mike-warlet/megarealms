// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MegaRealms Character v2
 * @notice NFT ERC-721 representando o personagem do jogador
 * @dev v2: saveProgress validations, stat limits, save cooldown, gold cap.
 *      Na Base L2, salvar estado e barato e rapido (2s blocks)
 */
contract GameCharacter is ERC721, Ownable {
    uint256 public nextCharId = 1;

    uint256 public constant MAX_LEVEL = 500;
    uint256 public constant MAX_GOLD = 99_999_999;
    uint256 public constant MAX_STAT = 10_000;
    uint256 public constant SAVE_COOLDOWN = 60; // 60 segundos entre saves

    struct CharacterData {
        string name;
        string vocation;
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
    mapping(address => uint256) public playerCharacter;

    /// @notice Enderecos autorizados a salvar em nome do jogador (game server)
    mapping(address => bool) public authorizedSavers;

    event CharacterMinted(address indexed player, uint256 indexed charId, string name, string vocation);
    event CharacterSaved(uint256 indexed charId, uint256 level, uint256 xp, uint256 gold);

    constructor() ERC721("MegaRealms Character", "MRCHAR") Ownable(msg.sender) {
        authorizedSavers[msg.sender] = true;
    }

    /// @notice Adiciona endereco autorizado a salvar (game server)
    function addSaver(address _saver) external onlyOwner {
        authorizedSavers[_saver] = true;
    }

    /// @notice Remove endereco autorizado
    function removeSaver(address _saver) external onlyOwner {
        authorizedSavers[_saver] = false;
    }

    /// @notice Cria um personagem (1 por wallet)
    function mintCharacter(string calldata name, string calldata vocation) external returns (uint256) {
        require(playerCharacter[msg.sender] == 0, "Ja possui um personagem");
        require(bytes(name).length > 0 && bytes(name).length <= 16, "Nome invalido");
        require(_isValidVocation(vocation), "Vocacao invalida");

        uint256 charId = nextCharId++;
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
            gold: 150,
            createdAt: block.timestamp,
            lastSaved: block.timestamp
        });

        playerCharacter[msg.sender] = charId;
        _mint(msg.sender, charId);

        emit CharacterMinted(msg.sender, charId, name, vocation);
        return charId;
    }

    /// @notice Salva o progresso (dono ou game server autorizado)
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
        // Autorização: dono do NFT ou game server autorizado
        require(
            ownerOf(charId) == msg.sender || authorizedSavers[msg.sender],
            "Nao autorizado"
        );

        CharacterData storage c = characters[charId];

        // Cooldown entre saves
        require(block.timestamp >= c.lastSaved + SAVE_COOLDOWN, "Cooldown de save");

        // Validacoes de limites
        require(level >= 1 && level <= MAX_LEVEL, "Level invalido");
        require(level >= c.level, "Level nao pode diminuir");
        require(hp <= maxHp && maxHp <= MAX_STAT, "HP invalido");
        require(mp <= maxMp && maxMp <= MAX_STAT, "MP invalido");
        require(atk <= MAX_STAT && def <= MAX_STAT, "Stat invalido");
        require(gold <= MAX_GOLD, "Gold excede maximo");

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

        emit CharacterSaved(charId, level, xp, gold);
    }

    function getCharacter(uint256 charId) external view returns (CharacterData memory) {
        require(charId > 0 && charId < nextCharId, "Character nao existe");
        return characters[charId];
    }

    function getPlayerCharId(address player) external view returns (uint256) {
        return playerCharacter[player];
    }

    /// @notice Valida vocacao
    function _isValidVocation(string calldata vocation) internal pure returns (bool) {
        bytes32 voc = keccak256(bytes(vocation));
        return (voc == keccak256("knight") || voc == keccak256("paladin") ||
                voc == keccak256("sorcerer") || voc == keccak256("druid"));
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
