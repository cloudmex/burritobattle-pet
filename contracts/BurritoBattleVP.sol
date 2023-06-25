// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "hardhat/console.sol";

contract BurritoBattleVP is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private nonce = 0;

    enum Activity {
        Idle,
        Playing,
        Eating,
        Sleeping
    }

    struct Pet {
        address owner;
        string image;
        string name;
        uint256 happiness;
        uint256 hunger;
        uint256 sleep;
        Activity currentActivity;
        uint256 lastMeal;
        uint256 lastSleep;
        uint256 lastPlay;
    }

    struct PetInfo {
        uint256 tokenId;
        string image;
        string name;
        uint256 happiness;
        uint256 hunger;
        uint256 sleep;
        string activity;
        bool isHungry;
        bool isSleepy;
        bool isBored;
    }

    struct TokenURI {
        string tokenURI;
        string image;
    }

    mapping(uint256 => Pet) private _pets;

    constructor() ERC721("Burrito Battle Virtual Pet", "BBVP") {}

    function mintPet(string memory petName) external returns (uint256) {
        _tokenIds.increment();
        uint256 newPetId = _tokenIds.current();
        _safeMint(msg.sender, newPetId);

        TokenURI memory tokenURI = generateTokenURI(petName);
        uint256 currentTime = block.timestamp;

        _pets[newPetId] = Pet(
            msg.sender,
            tokenURI.image,
            petName,
            50,
            0,
            0,
            Activity.Idle,
            currentTime,
            currentTime,
            currentTime
        );

        _setTokenURI(newPetId, tokenURI.tokenURI);

        return newPetId;
    }

    function play(uint256 tokenId) external {
        require(_exists(tokenId), "Pet does not exist");
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of the token"
        );

        Pet storage pet = _pets[tokenId];
        require(pet.currentActivity == Activity.Idle, "Pet is busy");

        uint256 currentTime = block.timestamp;
        
        if ((currentTime - pet.lastSleep) > 16 hours) {
            pet.happiness -= 10;
            pet.sleep += 10;
        }
        require((currentTime - pet.lastSleep) < 16 hours, "Pet is tired");

        //pet.currentActivity = Activity.Playing;
        pet.lastPlay = block.timestamp;
        pet.happiness == 50 ? 50 : pet.happiness += 10;
        pet.hunger == 50 ? 50 : pet.hunger += 10;

    }

    function eat(uint256 tokenId) external {
        require(_exists(tokenId), "Pet does not exist");
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of the token"
        );

        Pet storage pet = _pets[tokenId];
        require(pet.currentActivity == Activity.Idle, "Pet is busy");
        //pet.currentActivity = Activity.Eating;
        pet.lastMeal = block.timestamp;
        pet.hunger == 0 ? 0 : pet.hunger -= 10;
        pet.happiness == 50 ? 50 : pet.happiness += 10;
        pet.sleep == 50 ? 50 : pet.sleep += 10;
    }

    function doze(uint256 tokenId) external {
        require(_exists(tokenId), "Pet does not exist");
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of the token"
        );

        Pet storage pet = _pets[tokenId];
        require(pet.currentActivity == Activity.Idle, "Pet is busy");

        uint256 currentTime = block.timestamp;
        if ((currentTime - pet.lastMeal) > 6 hours) {
            pet.happiness -= 10;
            pet.hunger += 10;
        }
        require((currentTime - pet.lastMeal) < 6 hours, "Pet is hungry");

        //pet.currentActivity = Activity.Sleeping;
        pet.lastSleep = block.timestamp;
        pet.sleep == 0 ? 0 : pet.sleep -= 10;
        pet.happiness == 0 ? 0 : pet.happiness -= 10;
    }

    function getMintedTokens() external view returns (uint256) {
        return _tokenIds._value;
    }

    function checkStatus(uint256 petId)
        internal
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            string memory,
            bool,
            bool,
            bool
        )
    {
        require(_exists(petId), "Pet does not exist");
        Pet storage pet = _pets[petId];
        string memory activity = getActivityString(pet.currentActivity);

        uint256 currentTime = block.timestamp;

        bool isHungry = (currentTime - pet.lastMeal) > 6 hours || pet.hunger == 50;
        bool isSleepy = (currentTime - pet.lastSleep) > 16 hours || pet.sleep == 50;
        bool isBored = (currentTime - pet.lastPlay) > 3 hours || pet.happiness <= 20;

        return (
            pet.image,
            pet.name,
            pet.happiness,
            pet.hunger,
            pet.sleep,
            activity,
            isHungry,
            isSleepy,
            isBored
        );
    }

    function getTokenInfoById(uint256 tokenId)
        external
        view
        returns (PetInfo memory)
    {
        require(_exists(tokenId), "Token does not exist");
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of the token"
        );

        (
            string memory image,
            string memory name,
            uint256 happiness,
            uint256 hunger,
            uint256 sleep,
            string memory activity,
            bool isHungry,
            bool isSleepy,
            bool isBored
        ) = checkStatus(tokenId);

        return
            convertToPetInfo(
                tokenId,
                image,
                name,
                happiness,
                hunger,
                sleep,
                activity,
                isHungry,
                isSleepy,
                isBored
            );
    }

    function convertToPetInfo(
        uint256 tokenId,
        string memory image,
        string memory name,
        uint256 happiness,
        uint256 hunger,
        uint256 sleep,
        string memory activity,
        bool isHungry,
        bool isSleepy,
        bool isBored
    ) private pure returns (PetInfo memory) {
        return
            PetInfo({
                tokenId: tokenId,
                image: image,
                name: name,
                happiness: happiness,
                hunger: hunger,
                sleep: sleep,
                activity: activity,
                isHungry: isHungry,
                isSleepy: isSleepy,
                isBored: isBored
            });
    }

    function generateTokenURI(string memory petName)
        private
        returns (TokenURI memory)
    {
        uint256 randomImageIndex = random() % 3; // 3 different images

        string[3] memory images = [
            "https://pin.ski/3Jjp95g",
            "https://pin.ski/3NwRR57",
            "https://pin.ski/3JfJ1X6"
        ];

        string memory json = string(
            abi.encodePacked(
                '{"name": "',
                petName,
                '", "description": "A virtual pet NFT", "image": "',
                images[randomImageIndex],
                '", "attributes": [{"trait_type": "Happiness", "value": "',
                toString(_pets[_tokenIds.current()].happiness),
                '"}, {"trait_type": "Hunger", "value": "',
                toString(_pets[_tokenIds.current()].hunger),
                '"}, {"trait_type": "Activity", "value": "',
                getActivityString(_pets[_tokenIds.current()].currentActivity),
                '"}]}'
            )
        );

        string memory token = string(
            abi.encodePacked(
                "data:application/json;base64,",
                bytes(Base64.encode(bytes(json)))
            )
        );

        TokenURI memory tokenURI = TokenURI(
            token,
            string(images[randomImageIndex])
        );

        return tokenURI;
    }

    function random() private returns (uint256) {
        nonce++;
        return
            uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
            );
    }

    function getActivityString(Activity activity)
        private
        pure
        returns (string memory)
    {
        if (activity == Activity.Playing) {
            return "Playing";
        } else if (activity == Activity.Eating) {
            return "Eating";
        } else if (activity == Activity.Sleeping) {
            return "Sleeping";
        } else {
            return "Idle";
        }
    }

    function toString(uint256 value) private pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}