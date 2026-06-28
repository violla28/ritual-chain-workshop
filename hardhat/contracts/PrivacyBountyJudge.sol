// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PrivacyBountyJudge {
    address public owner;

    struct Bounty {
        uint256 submissionDeadline;
        uint256 revealDeadline;
        bool judgingStarted;
        uint256 winnerIndex;
        address[] revealedParticipants;
        mapping(address => bytes32) commitments;
        mapping(address => string) revealedAnswers;
        mapping(address => bool) hasRevealed;
    }

    mapping(uint256 => Bounty) public bounties;

    event CommitmentSubmitted(uint256 indexed bountyId, address indexed participant, bytes32 commitment);
    event AnswerRevealed(uint256 indexed bountyId, address indexed participant, string answer);
    event JudgingStarted(uint256 indexed bountyId);
    event WinnerFinalized(uint256 indexed bountyId, uint256 winnerIndex, address winner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Hanya owner yang boleh");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createBounty(uint256 bountyId, uint256 submissionDeadline, uint256 revealDeadline) external {
        require(bounties[bountyId].submissionDeadline == 0, "Bounty sudah ada");
        require(submissionDeadline > block.timestamp, "Deadline submission tidak valid");
        require(revealDeadline > submissionDeadline, "Reveal harus setelah submission");

        Bounty storage b = bounties[bountyId];
        b.submissionDeadline = submissionDeadline;
        b.revealDeadline = revealDeadline;
    }

    function submitCommitment(uint256 bountyId, bytes32 commitment) external {
        Bounty storage b = bounties[bountyId];
        require(block.timestamp < b.submissionDeadline, "Fase submission sudah selesai");
        require(commitment != bytes32(0), "Commitment tidak valid");
        require(b.commitments[msg.sender] == bytes32(0), "Sudah pernah commit");

        b.commitments[msg.sender] = commitment;
        emit CommitmentSubmitted(bountyId, msg.sender, commitment);
    }

    function revealAnswer(uint256 bountyId, string calldata answer, bytes32 salt) external {
        Bounty storage b = bounties[bountyId];
        require(block.timestamp >= b.submissionDeadline, "Belum masuk fase reveal");
        require(block.timestamp < b.revealDeadline, "Fase reveal sudah selesai");
        require(b.commitments[msg.sender] != bytes32(0), "Belum submit commitment");
        require(!b.hasRevealed[msg.sender], "Sudah pernah reveal");

        bytes32 expected = keccak256(abi.encodePacked(answer, salt, msg.sender, bountyId));
        require(expected == b.commitments[msg.sender], "Reveal tidak valid (hash salah)");

        b.revealedAnswers[msg.sender] = answer;
        b.hasRevealed[msg.sender] = true;
        b.revealedParticipants.push(msg.sender);

        emit AnswerRevealed(bountyId, msg.sender, answer);
    }

    function judgeAll(uint256 bountyId, bytes calldata llmInput) external onlyOwner {
        Bounty storage b = bounties[bountyId];
        require(block.timestamp >= b.revealDeadline, "Fase reveal belum selesai");
        require(!b.judgingStarted, "Sudah mulai judging");

        b.judgingStarted = true;
        emit JudgingStarted(bountyId);
    }

    function finalizeWinner(uint256 bountyId, uint256 winnerIndex) external onlyOwner {
        Bounty storage b = bounties[bountyId];
        require(b.judgingStarted, "Belum mulai judging");
        require(winnerIndex < b.revealedParticipants.length, "Index pemenang tidak valid");

        b.winnerIndex = winnerIndex;
        address winner = b.revealedParticipants[winnerIndex];
        emit WinnerFinalized(bountyId, winnerIndex, winner);
    }

    function getRevealedAnswers(uint256 bountyId) external view returns (address[] memory participants, string[] memory answers) {
        Bounty storage b = bounties[bountyId];
        uint256 len = b.revealedParticipants.length;
        participants = new address[](len);
        answers = new string[](len);

        for (uint256 i = 0; i < len; i++) {
            address p = b.revealedParticipants[i];
            participants[i] = p;
            answers[i] = b.revealedAnswers[p];
        }
    }
}
