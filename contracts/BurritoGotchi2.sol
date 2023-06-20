// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract VirtualPet is ERC721URIStorage, IERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private nonce = 0;
    uint256 private constant ROYALTY_PERCENTAGE = 1;

    enum Activity { Idle, Playing, Eating }

    struct Pet {
        string name;
        uint256 happiness;
        uint256 hunger;
        Activity currentActivity;
    }

    mapping(uint256 => Pet) private _pets;

    constructor() ERC721("VirtualPet", "VPET") {}

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
        uint256 randomImageIndex = random() % 5; // 5 different images

        string[5] memory images = [
            "https://example.com/image1.png",
            "https://example.com/image2.png",
            "https://example.com/image3.png",
            "https://example.com/image4.png",
            "https://example.com/image5.png"
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

        return string(abi.encodePacked("data:application/json;base64,", bytes(base64Encode(bytes(json)))));
    }

    function royaltyInfo(uint256 tokenId, uint256 value) external view override returns (address, uint256) {
        uint256 royaltyAmount = (value * ROYALTY_PERCENTAGE) / 100;
        return (owner(), royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC2981) returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
    }

    function random() private returns (uint256) {
        nonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce)));
    }

    function base64Encode(bytes memory input) private pure returns (string memory) {
        bytes memory alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        uint256 encodedLen = 4 * ((input.length + 2) / 3);
        bytes memory result = new bytes(encodedLen);

        uint256 resultIndex = 0;
        uint256 inputIndex = 0;

        assembly {
            let inputPtr := add(input, 0x20)
            let resultPtr := add(result, 0x20)

            for {
                let remainingBytes := mload(input)                        // input.length
                let i := 0
            } lt(i, div(remainingBytes, 3)) {
                i := add(i, 1)
            } {
                input := sub(input, 0x20)
                mstore(input, 0x20)                                      // Consume input in blocks of 3

                let first := mload(add(inputPtr, mul(i, 0x20)))
                let second := mload(add(inputPtr, mul(i, 0x20), 0x20))
                let third := mload(add(inputPtr, mul(i, 0x20), 0x40))

                let out := or(or(shl(2, and(shr(4, first), 0x3F)), shl(2, and(shr(10, first), 0x3F00))),
                                or(shl(2, and(shr(16, second), 0x3F)), shl(2, and(shr(22, second), 0x3F0000))))

                out := or(out, or(shl(2, and(shr(28, second), 0x3F000000))), or(shl(2, and(shr(6, third), 0x3F)),
                                shl(2, and(shr(14, third), 0x3FC000)))))

                mstore(add(resultPtr, mul(resultIndex, 0x20)), shl(224, out))
                resultIndex := add(resultIndex, 1)
            }

            let remainder := sub(remainingBytes, mul(div(remainingBytes, 3), 3))

            if gt(remainder, 0) {
                mstore(sub(resultPtr, 0x20), shl(240, 0x3D3D000000000000000000000000000000000000000000000000000000000000))
                // Padding

                let lastBytes := 0x3D00000000000000000000000000000000000000000000000000000000000000 // More padding

                if eq(remainder, 2) {
                    lastBytes := or(and(mload(add(inputPtr, mul(div(remainingBytes, 3), 0x20))), 0xFFFF00000000),
                                    shl(16, or(and(mload(add(inputPtr, mul(div(remainingBytes, 3), 0x20))), 0xFFFF), shl(8,
                                    and(mload(add(inputPtr, mul(div(remainingBytes, 3), 0x20))), 0xFF))))))

                    mstore(sub(resultPtr, 0x20), shl(240, or(shr(4, lastBytes), shl(12, and(shr(12, lastBytes), 0xFFFF)))))
                }
                else if eq(remainder, 1) {
                    lastBytes := and(mload(add(inputPtr, mul(div(remainingBytes, 3), 0x20))), 0xFF00000000000000000000000000000000000000000000000000000000000000)

                    mstore(sub(resultPtr, 0x20), shl(240, or(shr(10, lastBytes), shl(18, and(shr(2, lastBytes), 0xFFFF)))))
                }

                mstore(add(resultPtr, mul(resultIndex, 0x20)), shl(224, lastBytes))
            }

            mstore(result, encodedLen)                                    // Set the actual output length
        }

        return string(result);
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
