// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title SimpleVote — Système de vote on-chain avec fenêtre temporelle
/// @dev Supporte 4 candidats : Czmil, Yanisse, Lilian, Eckson
/// @dev Le vote se déroule dans une fenêtre temporelle configurable
/// @dev Une fois démarré, AUCUN contrôle possible jusqu'à la fin
contract SimpleVote is Ownable {
    // ======== Errors ========
    error AlreadyVoted();
    error VoteNotStarted();
    error VoteEnded();
    error VoteAlreadyStarted();
    error InvalidDuration();
    error InvalidCandidate();
    error InvalidCandidatesArray();

    // ======== Events ========
    event Voted(address indexed voter, uint256 indexed candidateIndex);
    event VoteStarted(uint256 startTime, uint256 endTime, uint256 duration);
    event VoteFinalized(uint256 endTime);

    // ======== Storage ========
    string[] private _candidates;
    mapping(uint256 => uint256) public votesCount;
    mapping(address => bool) public hasVoted;
    
    // Variables temporelles
    uint256 public voteStartTime;
    uint256 public voteEndTime;
    bool public voteStarted;
    bool public voteEnded;

    constructor(string[] memory candidates_, address initialOwner) Ownable(initialOwner) {
        if (candidates_.length < 2) revert InvalidCandidatesArray();
        _candidates = candidates_;
        // IMPORTANT: Le vote ne démarre PAS automatiquement
        voteStarted = false;
        voteEnded = false;
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

    function isVotingOpen() external view returns (bool) {
        return voteStarted && !voteEnded && block.timestamp >= voteStartTime && block.timestamp < voteEndTime;
    }

    function getVoteStatus() external view returns (
        bool started,
        bool ended,
        uint256 startTime,
        uint256 endTime,
        uint256 currentTime,
        uint256 remainingTime
    ) {
        uint256 remaining = 0;
        if (voteStarted && !voteEnded && block.timestamp < voteEndTime) {
            remaining = voteEndTime - block.timestamp;
        }
        
        return (
            voteStarted,
            voteEnded,
            voteStartTime,
            voteEndTime,
            block.timestamp,
            remaining
        );
    }

    // ======== Actions ========
    function startVote(uint256 durationInSeconds) external onlyOwner {
        if (voteStarted) revert VoteAlreadyStarted();
        if (durationInSeconds == 0) revert InvalidDuration();
        if (durationInSeconds > 7 days) revert InvalidDuration(); // Limite max 7 jours
        
        voteStarted = true;
        voteStartTime = block.timestamp;
        voteEndTime = block.timestamp + durationInSeconds;
        
        emit VoteStarted(voteStartTime, voteEndTime, durationInSeconds);
    }

    function vote(uint256 candidateIndex) external {
        // Contrôles stricts temporels
        if (!voteStarted) revert VoteNotStarted();
        if (voteEnded) revert VoteEnded();
        if (block.timestamp < voteStartTime) revert VoteNotStarted();
        if (block.timestamp >= voteEndTime) revert VoteEnded();
        
        if (hasVoted[msg.sender]) revert AlreadyVoted();
        if (candidateIndex >= _candidates.length) revert InvalidCandidate();

        hasVoted[msg.sender] = true;
        unchecked {
            votesCount[candidateIndex] += 1;
        }

        emit Voted(msg.sender, candidateIndex);
    }

    // Fonction pour finaliser le vote (peut être appelée par n'importe qui après la fin)
    function finalizeVote() external {
        if (!voteStarted) revert VoteNotStarted();
        if (voteEnded) return; // Déjà finalisé
        
        // Seulement si le temps est écoulé
        if (block.timestamp >= voteEndTime) {
            voteEnded = true;
            emit VoteFinalized(voteEndTime);
        }
    }

    // ======== Admin ========
    // SUPPRIMÉ: emergencyStop() - AUCUN contrôle après le démarrage

    // Refuser tout ETH envoyé par erreur
    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }
}
