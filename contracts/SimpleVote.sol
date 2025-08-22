// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title SimpleVote — Systeme de vote on-chain optimise
/// @dev Vote temporelle avec une liste de 4 candidats
/// @dev Optimisations: uint8 indices, bit flags, packed storage
/// @author Czmil
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
    event Voted(address indexed voter, uint8 indexed candidateIndex);
    event VoteStarted(uint32 startTime, uint32 endTime, uint16 duration);

    // ======== Storage (optimise) ========
    string[] private _candidates;
    uint32 private _voteStartTime;
    uint32 private _voteEndTime;
    mapping(uint8 => uint8) public votesCount;
    mapping(address => bool) public hasVoted; // bool reste optimal pour mapping
    
    // Variables temporelles packees
    uint8 private _voteState; // 0=not_started, 1=active, 2=ended

    // ======== Constants ========
    uint8 private constant NOT_STARTED = 0;
    uint8 private constant ACTIVE = 1;
    uint8 private constant ENDED = 2;
    uint8 private constant MAX_CANDIDATES = 4;
    uint16 private constant MIN_DURATION = 60;
    uint16 private constant MAX_DURATION = 3600; // 1 heure

    constructor(string[] memory candidates_, address initialOwner) Ownable(initialOwner) {
        if (candidates_.length < 2 || candidates_.length > MAX_CANDIDATES) {
            revert InvalidCandidatesArray();
        }
        _candidates = candidates_;
        _voteState = NOT_STARTED;
    }

    // ======== View Functions ========
    function candidates() external view returns (string[] memory) {
        return _candidates;
    }

    function getResults() external view returns (uint8[] memory counts) {
        uint8 n = uint8(_candidates.length);
        counts = new uint8[](n);
        for (uint8 i; i < n; ++i) {
            counts[i] = votesCount[i];
        }
    }

    function candidatesCount() external view returns (uint8) {
        return uint8(_candidates.length);
    }

    function isVotingOpen() external view returns (bool) {
        // Si le vote a expire, il n'est plus ouvert
        if (_voteState == ACTIVE && block.timestamp >= _voteEndTime) {
            return false;
        }
        return _voteState == ACTIVE && 
               block.timestamp >= _voteStartTime && 
               block.timestamp < _voteEndTime;
    }

    function getVoteStatus() external view returns (
        bool started,
        bool ended,
        uint32 startTime,
        uint32 endTime,
        uint32 currentTime,
        uint32 remainingTime
    ) {
        uint32 now32 = uint32(block.timestamp);
        uint32 remaining = _voteEndTime > now32 ? _voteEndTime - now32 : 0;
        
        return (
            _voteState >= ACTIVE,
            _voteState == ENDED,
            _voteStartTime,
            _voteEndTime,
            now32,
            remaining
        );
    }

    // ======== State Getters ========
    function voteStarted() external view returns (bool) {
        return _voteState >= ACTIVE;
    }

    function voteEnded() external view returns (bool) {
        return _voteState == ENDED;
    }

    function voteStartTime() external view returns (uint32) {
        return _voteStartTime;
    }

    function voteEndTime() external view returns (uint32) {
        return _voteEndTime;
    }

    // ======== Actions ========
    function startVote(uint16 durationInSeconds) external onlyOwner {
        if (_voteState >= ACTIVE) revert VoteAlreadyStarted();
        if (durationInSeconds < MIN_DURATION || durationInSeconds > MAX_DURATION) {
            revert InvalidDuration();
        }
        
        _voteState = ACTIVE;
        _voteStartTime = uint32(block.timestamp);
        _voteEndTime = uint32(block.timestamp + durationInSeconds);
        
        emit VoteStarted(_voteStartTime, _voteEndTime, durationInSeconds);
    }

    function vote(uint8 candidateIndex) external {
        // Controles optimises
        if (_voteState != ACTIVE) revert VoteNotStarted();
        if (block.timestamp < _voteStartTime || block.timestamp >= _voteEndTime) {
            revert VoteEnded();
        }
        if (hasVoted[msg.sender]) revert AlreadyVoted();
        if (candidateIndex >= _candidates.length) revert InvalidCandidate();

        hasVoted[msg.sender] = true;
        votesCount[candidateIndex]++;

        emit Voted(msg.sender, candidateIndex);
    }

    // ======== Fallbacks ========
    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }
}
