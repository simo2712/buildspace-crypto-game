// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract GameEngine is VRFConsumerBaseV2 {
    /* State Variables */
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionid;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint32 private constant ATTACK_IN_PROGRESS = 0;

    // A Mapping for the check of critical attacks or dodge
    mapping(uint256 => address) public s_attackers;
    mapping(address => uint256) public s_results;

    event RequestedRandomNumber(uint256 requestId, address sender);
    event RandomNumberCreated(uint256 requestId, uint256 randomNumber);

    constructor(
        address vrfCoordinatorV2, // contract
        bytes32 gasLane,
        uint64 subscriptionid,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionid = subscriptionid;
        i_callbackGasLimit = callbackGasLimit;
    }

    function requestRandonNumber() external {
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionid,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        s_attackers[requestId] = msg.sender;
        s_results[msg.sender] = ATTACK_IN_PROGRESS;
        emit RequestedRandomNumber(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 value = (randomWords[0] % 100) + 1;
        s_results[s_attackers[requestId]] = value;
        emit RandomNumberCreated(requestId, value);
    }

    function dodgeOrCritical(address sender, uint256 playerParameter) external view returns (bool) {
        if (s_results[sender] <= playerParameter) {
            return true;
        } else {
            return false;
        }
    }
}
