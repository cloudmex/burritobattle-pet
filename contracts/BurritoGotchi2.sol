// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract VirtualPet is ERC721URIStorage, IERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private nonce = 0;
    uint256 private constant ROYALTY_PERCENTAGE = 5;

    enum Activity { Idle, Playing, Eating }

    struct Pet {
        string name;
        uint256 happiness;
        uint256 hunger;
        Activity currentActivity;
    }

    mapping(uint256 => Pet) private _pets;

    constructor() ERC721("Burrito Gotchi", "BBGOT") {}

    function mintPet(string memory petName) external returns (uint256) {
        _tokenIds.increment();
        uint256 newPetId = _tokenIds.current();
        _safeMint(msg.sender, newPetId);
        _pets[newPetId] = Pet(petName, 50, 50, Activity.Idle);

        string memory tokenURI = generateTokenURI(petName);
        _setTokenURI(newPetId, tokenURI);

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

    function checkStatus(uint256 petId) external view returns (string memory, uint256, uint256, string memory) {
        require(_exists(petId), "Pet does not exist");
        Pet storage pet = _pets[petId];
        string memory activity = getActivityString(pet.currentActivity);
        return (pet.name, pet.happiness, pet.hunger, activity);
    }

    function generateTokenURI(string memory petName) private returns (string memory) {
        uint256 randomImageIndex = random() % 3; // 3 different images

        string[3] memory images = [
            "https://pin.ski/3Jjp95g",
            "https://pin.ski/3NwRR57",
            "https://pin.ski/3JfJ1X6"
        ];

        string memory json = string(
            abi.encodePacked(
                '{"name": "', petName,
                '", "description": "A virtual pet NFT", "image": "', images[randomImageIndex],
                '", "attributes": [{"trait_type": "Happiness", "value": "', toString(_pets[_tokenIds.current()].happiness),
                '"}, {"trait_type": "Hunger", "value": "', toString(_pets[_tokenIds.current()].hunger),
                '"}, {"trait_type": "Activity", "value": "', getActivityString(_pets[_tokenIds.current()].currentActivity),
                '"}]}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", bytes(Base64.encode(bytes(json)))));
    }

    function royaltyInfo(uint256 tokenId, uint256 value) external view override returns (address, uint256) {
        uint256 royaltyAmount = (value * ROYALTY_PERCENTAGE) / 100;
        return (ownerOf(), royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC2981) returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
    }

    function random() private returns (uint256) {
        nonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce)));
    }

    function getActivityString(Activity activity) private pure returns (string memory) {
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
