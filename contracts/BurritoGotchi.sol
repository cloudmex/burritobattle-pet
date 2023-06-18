// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BurritoGotchi is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant MAX_PETS = 1000;

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
        require(_tokenIds.current() < MAX_PETS, "Maximum number of pets reached");
        _tokenIds.increment();
        uint256 newPetId = _tokenIds.current();
        _safeMint(msg.sender, newPetId);
        _pets[newPetId] = Pet(petName, 50, 50, Activity.Idle);
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

    function getActivityString(Activity activity) private pure returns (string memory) {
        if (activity == Activity.Playing) {
            return "Playing";
        } else if (activity == Activity.Eating) {
            return "Eating";
        } else {
            return "Idle";
        }
    }
}
