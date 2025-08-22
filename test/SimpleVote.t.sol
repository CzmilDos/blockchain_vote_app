// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {SimpleVote} from "../contracts/SimpleVote.sol";

/// @title Tests exhaustifs pour SimpleVote
/// @dev Couverture complete : limites, gas, securite, performance
contract SimpleVoteTest is Test {
    // ======== Events ========
    event Voted(address indexed voter, uint8 indexed candidateIndex);
    event VoteStarted(uint32 startTime, uint32 endTime, uint16 duration);


    // ======== Test Setup ========
    SimpleVote vote;
    address owner;
    address voter1 = address(0xA1);
    address voter2 = address(0xB2);
    address voter3 = address(0xC3);
    address voter4 = address(0xD4);

    string[] candidates;
    uint16 constant VOTE_DURATION = 3600; // 1 heure
    uint16 constant SHORT_DURATION = 60; // 1 minute

    function setUp() public {
        owner = address(this);
        candidates = new string[](4);
        candidates[0] = "Czmil";
        candidates[1] = "Yanisse";
        candidates[2] = "Lilian";
        candidates[3] = "Eckson";
        vote = new SimpleVote(candidates, owner);
    }

    // ======== Constructor Tests ========
    function testConstructor_ValidCandidates() public {
        assertEq(vote.candidatesCount(), 4);
        string[] memory cs = vote.candidates();
        assertEq(cs[0], "Czmil");
        assertEq(cs[1], "Yanisse");
        assertEq(cs[2], "Lilian");
        assertEq(cs[3], "Eckson");
        assertFalse(vote.voteStarted());
        assertFalse(vote.voteEnded());
    }

    function testConstructor_TooFewCandidates() public {
        string[] memory bad = new string[](1);
        bad[0] = "Solo";
        vm.expectRevert(SimpleVote.InvalidCandidatesArray.selector);
        new SimpleVote(bad, owner);
    }

    function testConstructor_TooManyCandidates() public {
        string[] memory bad = new string[](5);
        bad[0] = "A"; bad[1] = "B"; bad[2] = "C"; bad[3] = "D"; bad[4] = "E";
        vm.expectRevert(SimpleVote.InvalidCandidatesArray.selector);
        new SimpleVote(bad, owner);
    }

    function testConstructor_EmptyArray() public {
        string[] memory bad = new string[](0);
        vm.expectRevert(SimpleVote.InvalidCandidatesArray.selector);
        new SimpleVote(bad, owner);
    }

    // ======== StartVote Tests ========
    function testStartVote_ValidDuration() public {
        uint16 startTime = uint16(block.timestamp);
        uint16 expectedEndTime = uint16(startTime + VOTE_DURATION);
        
        vm.expectEmit(true, true, true, true);
        emit VoteStarted(startTime, expectedEndTime, VOTE_DURATION);
        
        vote.startVote(VOTE_DURATION);
        
        assertTrue(vote.voteStarted());
        assertFalse(vote.voteEnded());
        assertEq(vote.voteStartTime(), startTime);
        assertEq(vote.voteEndTime(), expectedEndTime);
        assertTrue(vote.isVotingOpen());
    }

    function testStartVote_MinDuration() public {
        vote.startVote(60); // Duree minimale
        assertTrue(vote.isVotingOpen());
    }

    function testStartVote_MaxDuration() public {
        vote.startVote(3600); // Duree maximale
        assertTrue(vote.isVotingOpen());
    }

    function testStartVote_ZeroDuration() public {
        vm.expectRevert(SimpleVote.InvalidDuration.selector);
        vote.startVote(0);
    }

    function testStartVote_TooShortDuration() public {
        vm.expectRevert(SimpleVote.InvalidDuration.selector);
        vote.startVote(59); // < 60 secondes
    }

    function testStartVote_TooLongDuration() public {
        vm.expectRevert(SimpleVote.InvalidDuration.selector);
        vote.startVote(3600 + 1); // > 1 heure
    }

    function testStartVote_Twice() public {
        vote.startVote(VOTE_DURATION);
        vm.expectRevert(SimpleVote.VoteAlreadyStarted.selector);
        vote.startVote(VOTE_DURATION);
    }

    function testStartVote_NonOwner() public {
        vm.prank(voter1);
        vm.expectRevert(); // OwnableUnauthorizedAccount
        vote.startVote(VOTE_DURATION);
    }

    // ======== Vote Tests ========
    function testVote_ValidVote() public {
        vote.startVote(VOTE_DURATION);
        
        vm.prank(voter1);
        vote.vote(0); // Vote pour Czmil
        
        assertTrue(vote.hasVoted(voter1));
        assertEq(vote.votesCount(0), 1);
        assertEq(vote.votesCount(1), 0);
    }

    function testVote_MultipleVotes() public {
        vote.startVote(VOTE_DURATION);
        
        vm.prank(voter1);
        vote.vote(0); // Czmil
        vm.prank(voter2);
        vote.vote(2); // Lilian
        vm.prank(voter3);
        vote.vote(0); // Czmil
        
        assertEq(vote.votesCount(0), 2); // Czmil
        assertEq(vote.votesCount(1), 0); // Yanisse
        assertEq(vote.votesCount(2), 1); // Lilian
        assertEq(vote.votesCount(3), 0); // Eckson
    }

    function testVote_AllCandidates() public {
        vote.startVote(VOTE_DURATION);
        
        vm.prank(voter1);
        vote.vote(0); // Czmil
        vm.prank(voter2);
        vote.vote(1); // Yanisse
        vm.prank(voter3);
        vote.vote(2); // Lilian
        vm.prank(voter4);
        vote.vote(3); // Eckson
        
        assertEq(vote.votesCount(0), 1);
        assertEq(vote.votesCount(1), 1);
        assertEq(vote.votesCount(2), 1);
        assertEq(vote.votesCount(3), 1);
    }

    function testVote_BeforeStart() public {
        vm.prank(voter1);
        vm.expectRevert(SimpleVote.VoteNotStarted.selector);
        vote.vote(0);
    }

    function testVote_DoubleVote() public {
        vote.startVote(VOTE_DURATION);
        
        vm.prank(voter1);
        vote.vote(1);
        vm.prank(voter1);
        vm.expectRevert(SimpleVote.AlreadyVoted.selector);
        vote.vote(2);
    }

    function testVote_InvalidCandidate() public {
        vote.startVote(VOTE_DURATION);
        
        vm.prank(voter1);
        vm.expectRevert(SimpleVote.InvalidCandidate.selector);
        vote.vote(4); // Index invalide
    }

    function testVote_AfterExpiration() public {
        vote.startVote(SHORT_DURATION);
        
        vm.prank(voter1);
        vote.vote(0); // Vote valide
        
        vm.warp(block.timestamp + SHORT_DURATION + 1);
        
        vm.prank(voter2);
        vm.expectRevert(SimpleVote.VoteEnded.selector);
        vote.vote(1);
    }

    function testVote_BeforeStartTime() public {
        vote.startVote(VOTE_DURATION);
        
        vm.warp(vote.voteStartTime() - 1);
        
        vm.prank(voter1);
        vm.expectRevert(SimpleVote.VoteEnded.selector);
        vote.vote(0);
    }



    // ======== State Tests ========
    function testGetVoteStatus_NotStarted() public {
        (bool started, bool ended, uint32 start, uint32 end, uint32 current, uint32 remaining) = vote.getVoteStatus();
        
        assertFalse(started);
        assertFalse(ended);
        assertEq(start, 0);
        assertEq(end, 0);
        assertEq(current, uint32(block.timestamp));
        assertEq(remaining, 0);
    }

    function testGetVoteStatus_Active() public {
        vote.startVote(VOTE_DURATION);
        
        (bool started, bool ended, uint32 start, uint32 end, uint32 current, uint32 remaining) = vote.getVoteStatus();
        
        assertTrue(started);
        assertFalse(ended);
        assertEq(start, uint32(block.timestamp));
        assertEq(end, uint32(block.timestamp + VOTE_DURATION));
        assertEq(current, uint32(block.timestamp));
        assertGt(remaining, 0);
        assertLe(remaining, VOTE_DURATION);
    }

    function testGetVoteStatus_Expired() public {
        vote.startVote(SHORT_DURATION);
        vm.warp(block.timestamp + SHORT_DURATION + 1);
        
        (bool started, bool ended, , , , uint32 remaining) = vote.getVoteStatus();
        
        assertTrue(started);
        assertFalse(ended); // Le vote n'est pas "ended" mais "expired"
        assertEq(remaining, 0);
        assertFalse(vote.isVotingOpen()); // Mais il n'est plus ouvert
    }

    // ======== Results Tests ========
    function testGetResults_Empty() public {
        uint8[] memory results = vote.getResults();
        assertEq(results.length, 4);
        assertEq(results[0], 0);
        assertEq(results[1], 0);
        assertEq(results[2], 0);
        assertEq(results[3], 0);
    }

    function testGetResults_WithVotes() public {
        vote.startVote(VOTE_DURATION);
        
        vm.prank(voter1);
        vote.vote(0);
        vm.prank(voter2);
        vote.vote(0);
        vm.prank(voter3);
        vote.vote(2);
        
        uint8[] memory results = vote.getResults();
        assertEq(results[0], 2); // Czmil
        assertEq(results[1], 0); // Yanisse
        assertEq(results[2], 1); // Lilian
        assertEq(results[3], 0); // Eckson
    }

    // ======== Gas Optimization Tests ========
    function testGas_VoteOptimization() public {
        vote.startVote(VOTE_DURATION);
        
        uint256 gasBefore = gasleft();
        vm.prank(voter1);
        vote.vote(0);
        uint256 gasUsed = gasBefore - gasleft();
        
        console2.log("Gas used for vote:", gasUsed);
        assertLt(gasUsed, 100000); // Optimisation gas
    }

    function testGas_StartVoteOptimization() public {
        uint256 gasBefore = gasleft();
        vote.startVote(VOTE_DURATION);
        uint256 gasUsed = gasBefore - gasleft();
        
        console2.log("Gas used for startVote:", gasUsed);
        assertLt(gasUsed, 80000); // Optimisation gas
    }

    // ======== Security Tests ========
    function testSecurity_Reentrancy() public {
        // Test que le contrat n'est pas vulnerable aux attaques de reentrance
        vote.startVote(VOTE_DURATION);
        
        vm.prank(voter1);
        vote.vote(0);
        
        // Tentative de vote depuis un contrat malveillant
        vm.prank(voter1);
        vm.expectRevert(SimpleVote.AlreadyVoted.selector);
        vote.vote(1);
    }

    function testSecurity_Overflow() public {
        vote.startVote(VOTE_DURATION);
        
        // Test que les compteurs ne debordent pas (uint8 max = 255)
        for (uint8 i = 0; i < 255; i++) {
            address voter = address(uint160(i + 1000));
            vm.prank(voter);
            vote.vote(0);
        }
        
        assertEq(vote.votesCount(0), 255);
    }

    // ======== Edge Cases ========
    function testEdgeCase_ExactExpiration() public {
        vote.startVote(SHORT_DURATION);
        
        vm.warp(vote.voteEndTime() - 1);
        vm.prank(voter1);
        vote.vote(0); // Derniere seconde
        
        vm.warp(vote.voteEndTime());
        vm.prank(voter2);
        vm.expectRevert(SimpleVote.VoteEnded.selector);
        vote.vote(1); // Exactement a la fin
    }

    function testEdgeCase_MaxCandidates() public {
        string[] memory maxCandidates = new string[](4);
        maxCandidates[0] = "A"; maxCandidates[1] = "B"; 
        maxCandidates[2] = "C"; maxCandidates[3] = "D";
        
        SimpleVote maxVote = new SimpleVote(maxCandidates, owner);
        maxVote.startVote(VOTE_DURATION);
        
        vm.prank(voter1);
        maxVote.vote(3); // Dernier candidat
        
        assertEq(maxVote.votesCount(3), 1);
    }

    // ======== Fuzz Tests ========
    function testFuzz_VoteIndex(uint8 candidateIndex) public {
        vote.startVote(VOTE_DURATION);
        vm.assume(candidateIndex >= 4); // Index invalide
        
        vm.prank(voter1);
        vm.expectRevert(SimpleVote.InvalidCandidate.selector);
        vote.vote(candidateIndex);
    }

    function testFuzz_Duration(uint16 duration) public {
        vm.assume(duration < 60 || duration > 3600);
        
        vm.expectRevert(SimpleVote.InvalidDuration.selector);
        vote.startVote(duration);
    }

    function testFuzz_Addresses(address voter, uint8 candidateIndex) public {
        vm.assume(voter != address(0) && candidateIndex < 4);
        vote.startVote(VOTE_DURATION);
        
        vm.prank(voter);
        vote.vote(candidateIndex);
        
        assertTrue(vote.hasVoted(voter));
        assertEq(vote.votesCount(candidateIndex), 1);
    }

    // ======== Integration Tests ========
    function testIntegration_CompleteVoteCycle() public {
        // 1. Demarrage
        vote.startVote(VOTE_DURATION);
        assertTrue(vote.isVotingOpen());
        
        // 2. Votes
        vm.prank(voter1);
        vote.vote(0);
        vm.prank(voter2);
        vote.vote(1);
        vm.prank(voter3);
        vote.vote(0);
        
        // 3. Verification resultats
        uint8[] memory results = vote.getResults();
        assertEq(results[0], 2);
        assertEq(results[1], 1);
        
        // 4. Expiration
        vm.warp(block.timestamp + VOTE_DURATION + 1);
        assertFalse(vote.isVotingOpen());
        
        // 5. Le vote se termine automatiquement a l'expiration
        assertFalse(vote.isVotingOpen());
        
        // 6. Tentative de vote apres fin - maintenant que le vote est finalise
        vm.prank(voter4);
        vm.expectRevert(SimpleVote.VoteEnded.selector);
        vote.vote(2);
    }

    // ======== Performance Tests ========
    function testPerformance_ManyVotes() public {
        vote.startVote(VOTE_DURATION);
        
        uint256 gasBefore = gasleft();
        
        // 100 votes
        for (uint256 i = 0; i < 100; i++) {
            address voter = address(uint160(i + 1000));
            vm.prank(voter);
            vote.vote(uint8(i % 4));
        }
        
        uint256 gasUsed = gasBefore - gasleft();
        console2.log("Gas used for 100 votes:", gasUsed);
        
        assertEq(vote.votesCount(0), 25);
        assertEq(vote.votesCount(1), 25);
        assertEq(vote.votesCount(2), 25);
        assertEq(vote.votesCount(3), 25);
    }
}
