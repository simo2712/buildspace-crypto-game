// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "hardhat/console.sol";
import "./libraries/Base64.sol";

error MyEpicGame__CharacterHPEqualsToZero();
error MyEpicGame__BossHPEqualsToZero();

// Our contract inherits from ERC721, which is the standard NFT contract!
contract MyEpicGame is ERC721, VRFConsumerBaseV2 {
    /* State Variables */
    struct CharacterAttributes {
        uint characterIndex;
        string name;
        string imageURI;
        uint level;
        uint exp;
        uint maxExp;
        uint hp;
        uint maxHp;
        uint attackDamage;
        uint dexterity;
        uint luck;
    }
    struct BossAttributes {
        uint bossIndex;
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint attackDamage;
        uint bossExp;
    }

    // Use counter to increase the index of the next NFT
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    CharacterAttributes[] defaultCharacters;
    BossAttributes[] defaultBosses;

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    address owner;
    uint256 s_maxLevel;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionid;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // We create a mapping from the nft's tokenId => that NFTs attributes.
    mapping(uint256 => CharacterAttributes) public nftHolderAttributes;
    mapping(uint256 => BossAttributes) public bossAttributes;

    // A mapping from an address => the NFTs tokenId
    mapping(address => uint256) public nftHolders;

    event CharacterNFTMinted(
        address sender,
        uint256 tokenId,
        uint256 characterIndex
    );
    event AttackComplete(
        address sender,
        uint256 newBossHp,
        uint256 newCharacterHp
    );
    event BossKilled(address sender);

    constructor(address vrfCoordinatorV2, // contract
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionid,
        uint32 callbackGasLimit
    ) ERC721("Heroes", "HERO") VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionid = subscriptionid;
        i_callbackGasLimit = callbackGasLimit;
        owner = msg.sender;
        s_maxLevel = 20;
        // I increment _tokenIds here so that my first NFT has an ID of 1.
        _tokenIds.increment();
    }

    function createBosses(
        string[] memory bossName,
        string[] memory bossImageURI,
        uint[] memory bossHp,
        uint[] memory bossAttackDamage,
        uint[] memory bossExp
    ) public {
        uint256 lastBossIndex = defaultBosses.length;
        for (uint i = 0; i < bossName.length; i += 1) {
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

            console.log(
                "Done initializing %s w/ HP %s, img %s",
                b.name,
                b.hp,
                b.imageURI
            );
        }
    }

    function createCharacters(
        string[] memory characterNames,
        string[] memory characterImageURIs,
        uint[] memory characterHp,
        uint[] memory characterAttackDmg,
        uint[] memory characterDexterity,
        uint[] memory characterLuck
    ) public {
        uint256 lastIndex = defaultCharacters.length;
        for (uint i = 0; i < characterNames.length; i += 1) {
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
    function mintCharacterNFT(uint _characterIndex) external {
        // Get current tokenId (starts at 1 since we incremented in the constructor).
        uint256 newItemId = _tokenIds.current();

        // The magical function! Assigns the tokenId to the caller's wallet address.
        _safeMint(msg.sender, newItemId);

        // We map the tokenId => their character attributes. More on this in
        // the lesson below.
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

        console.log(
            "Minted NFT w/ tokenId %s and characterIndex %s",
            newItemId,
            _characterIndex
        );

        // Keep an easy way to see who owns what NFT.
        nftHolders[msg.sender] = newItemId;

        // Increment the tokenId for the next person that uses it.
        _tokenIds.increment();
        emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        CharacterAttributes memory charAttributes = nftHolderAttributes[
            _tokenId
        ];

        string memory strHp = Strings.toString(charAttributes.hp);
        string memory strMaxHp = Strings.toString(charAttributes.maxHp);
        string memory strAttackDamage = Strings.toString(
            charAttributes.attackDamage
        );

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

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function attackBoss(uint256 bossIndex) public {
        uint nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[
            nftTokenIdOfPlayer
        ];
        BossAttributes storage bigBoss = defaultBosses[bossIndex];
        console.log(
            "\nPlayer w/ character %s about to attack. Has %s HP and %s AD",
            player.name,
            player.hp,
            player.attackDamage
        );

        console.log(
            "Boss %s has %s HP and %s AD",
            bigBoss.name,
            bigBoss.hp,
            bigBoss.attackDamage
        );

        // We need to make sure that the player has enough HP to attack.
        if (player.hp < 0) revert MyEpicGame__CharacterHPEqualsToZero();

        // We need to make sure that the boss has enough HP to attack.
        if (bigBoss.hp < 0) revert MyEpicGame__BossHPEqualsToZero();

        // Allow player to attack boss.
        if (bigBoss.hp < player.attackDamage) {
            bigBoss.hp = 0;
        } else {
            bigBoss.hp = bigBoss.hp - player.attackDamage;
        }

        // Allow boss to attack player.
        if (player.hp < bigBoss.attackDamage) {
            player.hp = 0;
        } else {
            player.hp = player.hp - bigBoss.attackDamage;
        }

        // Console for ease.
        emit AttackComplete(msg.sender, bigBoss.hp, player.hp);
        console.log("Player attacked boss. New boss hp: %s", bigBoss.hp);
        console.log("Boss attacked player. New player hp: %s\n", player.hp);

        if (bigBoss.hp == 0) {
            console.log("Boss is dead!");
            addExp(bigBoss.bossExp);
            emit BossKilled(msg.sender);
        }
    }

    function addExp(uint expAdded) private {
        uint nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[
            nftTokenIdOfPlayer
        ];
        player.exp += expAdded;
        while (player.exp >= player.maxExp) {
            if (player.level == maxLevel && player.exp >= player.maxExp) {
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
        console.log("New hp: %s", player.hp);
    }

    function checkIfUserHasNFT()
        public
        view
        returns (CharacterAttributes memory)
    {
        uint nftTokenIdOfPlayer = nftHolders[msg.sender];
        if (nftTokenIdOfPlayer != 0) {
            return nftHolderAttributes[nftTokenIdOfPlayer];
        } else {
            CharacterAttributes memory emptyStruct;
            return emptyStruct;
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function incrementMaxLevel(uint256 newMaxLevel) public onlyOwner {
        maxLevel = newMaxLevel;
    }

    function getAllDefaultCharacters()
        public
        view
        returns (CharacterAttributes[] memory)
    {
        return defaultCharacters;
    }

    function getBossAttributes(uint256 bossIndex)
        public
        view
        returns (BossAttributes memory)
    {
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
