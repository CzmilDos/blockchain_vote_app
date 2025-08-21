// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title SimpleVote — Système de vote on-chain, un électeur = un vote, résultats publics
contract SimpleVote is Ownable {
    // ======== Errors ========
    error AlreadyVoted();
    error ErrVotingClosed(); // renommé pour éviter conflit avec l'event VotingClosed
    error ErrVotingOpen(); // renommé pour éviter conflit avec l'event VotingOpened
    error InvalidCandidate();
    error InvalidCandidatesArray();

    // ======== Events ========
    event Voted(address indexed voter, uint256 indexed candidateIndex);
    event VotingOpened();
    event VotingClosed();

    // ======== Storage ========
    string[] private _candidates;
    mapping(uint256 => uint256) public votesCount;
    mapping(address => bool) public hasVoted;
    bool public votingOpen;

    constructor(string[] memory candidates_, address initialOwner) Ownable(initialOwner) {
        if (candidates_.length < 2) revert InvalidCandidatesArray();
        _candidates = candidates_;
        votingOpen = true;
        emit VotingOpened();
    }

    // ======== Views ========
    function candidates() external view returns (string[] memory) {
        return _candidates;
    }

    function getResults() external view returns (uint256[] memory counts) {
        uint256 n = _candidates.length;
        counts = new uint256[](n);
        for (uint256 i; i < n; ++i) {
            counts[i] = votesCount[i];
        }
    }

    function candidatesCount() external view returns (uint256) {
        return _candidates.length;
    }

    // ======== Actions ========
    function vote(uint256 candidateIndex) external {
        if (!votingOpen) revert ErrVotingClosed();
        if (hasVoted[msg.sender]) revert AlreadyVoted();
        if (candidateIndex >= _candidates.length) revert InvalidCandidate();

        hasVoted[msg.sender] = true;
        unchecked {
            votesCount[candidateIndex] += 1;
        }

        emit Voted(msg.sender, candidateIndex);
    }

    function closeVoting() external onlyOwner {
        if (!votingOpen) revert ErrVotingClosed();
        votingOpen = false;
        emit VotingClosed();
    }

    function openVoting() external onlyOwner {
        if (votingOpen) revert ErrVotingOpen();
        votingOpen = true;
        emit VotingOpened();
    }

    // Refuser tout ETH envoyé par erreur
    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }
}
