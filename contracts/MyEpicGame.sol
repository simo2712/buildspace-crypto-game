// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";
import "./libraries/Base64.sol";
import "./GameEngine.sol";

error MyEpicGame__CharacterHPEqualsToZero();
error MyEpicGame__BossHPEqualsToZero();

// Our contract inherits from ERC721, which is the standard NFT contract!
contract MyEpicGame is ERC721 {
    /* State Variables */
    struct CharacterAttributes {
        uint256 characterIndex;
        string name;
        string imageURI;
        uint256 level;
        uint256 exp;
        uint256 maxExp;
        uint256 hp;
        uint256 maxHp;
        uint256 attackDamage;
        uint256 dexterity;
        uint256 luck;
    }

    struct BossAttributes {
        uint256 bossIndex;
        string name;
        string imageURI;
        uint256 hp;
        uint256 maxHp;
        uint256 attackDamage;
        uint256 bossExp;
    }

    // Use counter to increase the index of the next NFT
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    CharacterAttributes[] defaultCharacters;
    BossAttributes[] defaultBosses;

    address i_owner;
    uint256 s_maxLevel;

    // We create a mapping from the nft's tokenId => that NFTs attributes.
    mapping(uint256 => CharacterAttributes) public nftHolderAttributes;
    mapping(uint256 => BossAttributes) public bossAttributes;

    // A mapping from an address => the NFTs tokenId
    mapping(address => uint256) public nftHolders;

    event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
    event AttackComplete(address sender, uint256 newBossHp, uint256 newCharacterHp);
    event BossKilled(address sender);

    constructor() ERC721("Heroes", "HERO") {
        i_owner = msg.sender;
        s_maxLevel = 20;
        _tokenIds.increment();
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner);
        _;
    }

    function createBosses(
        string[] memory bossName,
        string[] memory bossImageURI,
        uint256[] memory bossHp,
        uint256[] memory bossAttackDamage,
        uint256[] memory bossExp
    ) public onlyOwner {
        uint256 lastBossIndex = defaultBosses.length;
        for (uint256 i = 0; i < bossName.length; i += 1) {
            defaultBosses.push(
                BossAttributes({
                    bossIndex: i + lastBossIndex,
                    name: bossName[i],
                    imageURI: bossImageURI[i],
                    hp: bossHp[i],
                    maxHp: bossHp[i],
                    attackDamage: bossAttackDamage[i],
                    bossExp: bossExp[i]
                })
            );

            BossAttributes memory b = defaultBosses[i];

            console.log("Done initializing %s w/ HP %s, img %s", b.name, b.hp, b.imageURI);
        }
    }

    function createCharacters(
        string[] memory characterNames,
        string[] memory characterImageURIs,
        uint256[] memory characterHp,
        uint256[] memory characterAttackDmg,
        uint256[] memory characterDexterity,
        uint256[] memory characterLuck
    ) public onlyOwner {
        uint256 lastIndex = defaultCharacters.length;
        for (uint256 i = 0; i < characterNames.length; i += 1) {
            defaultCharacters.push(
                CharacterAttributes({
                    characterIndex: i + lastIndex,
                    name: characterNames[i],
                    imageURI: characterImageURIs[i],
                    level: 1,
                    exp: 0,
                    maxExp: 1000,
                    hp: characterHp[i],
                    maxHp: characterHp[i],
                    attackDamage: characterAttackDmg[i],
                    dexterity: characterDexterity[i],
                    luck: characterLuck[i]
                })
            );

            CharacterAttributes memory c = defaultCharacters[i + lastIndex];

            // Hardhat's use of console.log() allows up to 4 parameters in any order of following types: uint, string, bool, address
            console.log(
                "Done initializing %s w/ HP %s and index %s",
                c.name,
                c.hp,
                c.characterIndex
            );
        }
    }

    // Users would be able to hit this function and get their NFT based on the
    // characterId they send in!
    function mintCharacterNFT(uint256 _characterIndex) external {
        // Get current tokenId (starts at 1 since we incremented in the constructor).
        uint256 newItemId = _tokenIds.current();

        // The magical function! Assigns the tokenId to the caller's wallet address.
        _safeMint(msg.sender, newItemId);

        // We map the tokenId => their character attributes.
        nftHolderAttributes[newItemId] = CharacterAttributes({
            characterIndex: _characterIndex,
            name: defaultCharacters[_characterIndex].name,
            imageURI: defaultCharacters[_characterIndex].imageURI,
            level: defaultCharacters[_characterIndex].level,
            exp: defaultCharacters[_characterIndex].exp,
            maxExp: defaultCharacters[_characterIndex].maxExp,
            hp: defaultCharacters[_characterIndex].hp,
            maxHp: defaultCharacters[_characterIndex].maxHp,
            attackDamage: defaultCharacters[_characterIndex].attackDamage,
            dexterity: defaultCharacters[_characterIndex].dexterity,
            luck: defaultCharacters[_characterIndex].luck
        });

        // Keep an easy way to see who owns what NFT.
        nftHolders[msg.sender] = newItemId;

        // Increment the tokenId for the next person that uses it.
        _tokenIds.increment();
        emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

        string memory strHp = Strings.toString(charAttributes.hp);
        string memory strMaxHp = Strings.toString(charAttributes.maxHp);
        string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                charAttributes.name,
                " -- NFT #: ",
                Strings.toString(_tokenId),
                '", "description": "This is an NFT that lets people play in the game Metaverse Slayer!", "image": "',
                charAttributes.imageURI,
                '", "attributes": [ { "trait_type": "Health Points", "value": ',
                strHp,
                ', "max_value":',
                strMaxHp,
                '}, { "trait_type": "Attack Damage", "value": ',
                strAttackDamage,
                "} ]}"
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function attackBoss(GameEngine _contract, uint256 bossIndex) public {
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
        BossAttributes storage bigBoss = defaultBosses[bossIndex];

        // We need to make sure that the player has enough HP to attack.
        if (player.hp == 0) revert MyEpicGame__CharacterHPEqualsToZero();

        // We need to make sure that the boss has enough HP to attack.
        if (bigBoss.hp == 0) revert MyEpicGame__BossHPEqualsToZero();

        // Allow player to attack boss.
        _contract.requestRandonNumber();
        if (bigBoss.hp < player.attackDamage) {
            bigBoss.hp = 0;
        } else {
            if (_contract.dodgeOrCritical(msg.sender, player.luck)) {
                bigBoss.hp -= player.attackDamage * 2;
            }
            bigBoss.hp -= player.attackDamage;
        }

        // Allow boss to attack player.
        _contract.requestRandonNumber();
        if (_contract.dodgeOrCritical(msg.sender, player.dexterity)) {
            console.log("Attack dodged!");
        } else {
            if (player.hp < bigBoss.attackDamage) {
                player.hp = 0;
            } else {
                player.hp = player.hp - bigBoss.attackDamage;
            }
        }

        // Console for ease.
        emit AttackComplete(msg.sender, bigBoss.hp, player.hp);
        console.log("Player attacked boss. New boss hp: %s.", bigBoss.hp);
        console.log("Boss attacked player. New player hp: %s\n", player.hp);

        if (bigBoss.hp == 0) {
            console.log("Boss is dead!");
            addExp(bigBoss.bossExp);
            emit BossKilled(msg.sender);
        }
    }

    function addExp(uint256 expAdded) private {
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
        player.exp += expAdded;
        while (player.exp >= player.maxExp) {
            if (player.level == s_maxLevel && player.exp >= player.maxExp) {
                player.exp = player.maxExp;
                console.log("Player is max level!");
                break;
            }
            player.exp -= player.maxExp;
            player.level += 1;
            player.maxExp = player.maxExp * 2;
            player.hp = player.maxHp;
        }

        console.log("New level: %s", player.level);
        console.log("Boss xp added: %s", expAdded);
        console.log("New exp: %s", player.exp);
        console.log("New maxExp: %s", player.maxExp);
    }

    function incrementsMaxLevel(uint256 new_maxLevel) public onlyOwner {
        s_maxLevel = new_maxLevel;
    }

    function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        if (nftTokenIdOfPlayer != 0) {
            return nftHolderAttributes[nftTokenIdOfPlayer];
        } else {
            CharacterAttributes memory emptyStruct;
            return emptyStruct;
        }
    }

    function getOwnerOfContract() public view returns (address) {
        return i_owner;
    }

    function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
        return defaultCharacters;
    }

    function getBossAttributes(uint256 bossIndex) public view returns (BossAttributes memory) {
        return defaultBosses[bossIndex];
    }

    function getCharacterAttributes(uint256 characterIndex)
        public
        view
        returns (CharacterAttributes memory)
    {
        return defaultCharacters[characterIndex];
    }
}
