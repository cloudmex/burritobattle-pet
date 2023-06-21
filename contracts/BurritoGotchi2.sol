// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "hardhat/console.sol";

contract BurritoBattleVP is ERC721URIStorage {
    event MensajeImpreso(string mensaje);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private nonce = 0;

    enum Activity {
        Idle,
        Playing,
        Eating
    }

    struct Pet {
        address owner;
        string image;
        string name;
        uint256 happiness;
        uint256 hunger;
        Activity currentActivity;
    }

    struct PetInfo {
        uint256 tokenId;
        string image;
        string name;
        uint256 happiness;
        uint256 hunger;
        string activity;
    }

    struct TokenURI {
        string tokenURI;
        string image;
    }

    mapping(uint256 => Pet) private _pets;

    constructor() ERC721("Burrito battle Virtual Pet", "BBVP") {}

    function mintPet(string memory petName) external returns (uint256) {
        _tokenIds.increment();
        uint256 newPetId = _tokenIds.current();
        _safeMint(msg.sender, newPetId);

        TokenURI memory tokenURI = generateTokenURI(petName);

        emit MensajeImpreso(tokenURI.image);

        _pets[newPetId] = Pet(
            msg.sender,
            tokenURI.image,
            petName,
            50,
            50,
            Activity.Idle
        );

        _setTokenURI(newPetId, tokenURI.tokenURI);

        return newPetId;
    }

    function play(uint256 petId) external {
        require(_exists(petId), "Pet does not exist");
        Pet storage pet = _pets[petId];
        require(pet.currentActivity == Activity.Idle, "Pet is busy");
        pet.currentActivity = Activity.Playing;
        pet.happiness += 10;
    }

    function eat(uint256 petId) external {
        require(_exists(petId), "Pet does not exist");
        Pet storage pet = _pets[petId];
        require(pet.currentActivity == Activity.Idle, "Pet is busy");
        pet.currentActivity = Activity.Eating;
        pet.hunger += 10;
    }

    function checkStatus(uint256 petId)
        internal
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256,
            string memory
        )
    {
        require(_exists(petId), "Pet does not exist");
        Pet storage pet = _pets[petId];
        string memory activity = getActivityString(pet.currentActivity);
        return (pet.image, pet.name, pet.happiness, pet.hunger, activity);
    }

 
    function getTokenInfoById(uint256 tokenId)
        external
        view
        returns (PetInfo memory)
    {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the owner of the token");

        (
            string memory image,
            string memory name,
            uint256 happiness,
            uint256 hunger,
            string memory activity
        ) = checkStatus(tokenId);

        return
            convertToPetInfo(tokenId, image, name, happiness, hunger, activity);
    }

    function convertToPetInfo(
        uint256 tokenId,
        string memory image,
        string memory name,
        uint256 happiness,
        uint256 hunger,
        string memory activity
    ) private pure returns (PetInfo memory) {
        return
            PetInfo({
                tokenId: tokenId,
                image: image,
                name: name,
                happiness: happiness,
                hunger: hunger,
                activity: activity
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