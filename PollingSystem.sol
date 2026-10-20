// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PollingSystem {
    struct Poll {
        string title;
        string[] options;
        uint256 endTime;
        mapping(uint256 => uint256) voteCount;   // option index => votes
    }

    uint256 public pollCount;
    mapping(uint256 => Poll) private polls;                        // pollId => Poll
    mapping(uint256 => mapping(address => bool)) public hasVoted;  // pollId => voter => voted?

    event PollCreated(uint256 indexed pollId, string title, uint256 endTime);
    event Voted(uint256 indexed pollId, address indexed voter, uint256 optionIndex);

    function createPoll(
        string calldata title,
        string[] calldata options,
        uint256 durationInSeconds
    ) public returns (uint256) {
        require(options.length >= 2, "Need at least 2 options");
        require(durationInSeconds > 0, "Duration must be positive");

        uint256 pollId = pollCount;
        pollCount++;

        Poll storage p = polls[pollId];
        p.title = title;
        p.endTime = block.timestamp + durationInSeconds;
        for (uint256 i = 0; i < options.length; i++) {
            p.options.push(options[i]);
        }

        emit PollCreated(pollId, title, p.endTime);
        return pollId;
    }

    function vote(uint256 pollId, uint256 optionIndex) public {
        require(pollId < pollCount, "Poll does not exist");
        Poll storage p = polls[pollId];

        require(block.timestamp < p.endTime, "Poll has ended");
        require(!hasVoted[pollId][msg.sender], "Already voted");
        require(optionIndex < p.options.length, "Invalid option");

        hasVoted[pollId][msg.sender] = true;
        p.voteCount[optionIndex] += 1;

        emit Voted(pollId, msg.sender, optionIndex);
    }

    function getPoll(uint256 pollId)
        public
        view
        returns (string memory title, string[] memory options, uint256 endTime)
    {
        require(pollId < pollCount, "Poll does not exist");
        Poll storage p = polls[pollId];
        return (p.title, p.options, p.endTime);
    }

    function getVotes(uint256 pollId, uint256 optionIndex) public view returns (uint256) {
        require(pollId < pollCount, "Poll does not exist");
        return polls[pollId].voteCount[optionIndex];
    }

    function getWinner(uint256 pollId)
        public
        view
        returns (string memory winnerName, uint256 winnerVotes)
    {
        require(pollId < pollCount, "Poll does not exist");
        Poll storage p = polls[pollId];
        require(block.timestamp >= p.endTime, "Poll not ended yet");

        uint256 winningIndex = 0;
        for (uint256 i = 1; i < p.options.length; i++) {
            if (p.voteCount[i] > p.voteCount[winningIndex]) {
                winningIndex = i;
            }
        }

        require(p.voteCount[winningIndex] > 0, "No votes were cast");
        return (p.options[winningIndex], p.voteCount[winningIndex]);
    }
}