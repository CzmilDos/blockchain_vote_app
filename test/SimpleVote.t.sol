// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {SimpleVote} from "../contracts/SimpleVote.sol";

contract SimpleVoteTest is Test {
    // Re-déclare les évènements pour expectEmit
    event Voted(address indexed voter, uint256 indexed candidateIndex);
    event VoteStarted(uint256 startTime, uint256 endTime, uint256 duration);
    event VoteFinalized(uint256 endTime);

    SimpleVote vote;
    address owner;
    address a = address(0xA1);
    address b = address(0xB2);
    address c = address(0xC3);

    string[] names;
    uint256 constant VOTE_DURATION = 3600; // 1 heure

    function setUp() public {
        owner = address(this);
        names = new string[](4);
        names[0] = "Czmil";
        names[1] = "Yanisse";
        names[2] = "Lilian";
        names[3] = "Eckson";
        vote = new SimpleVote(names, owner);
    }

    function testInitialState() public {
        assertFalse(vote.voteStarted());
        assertFalse(vote.voteEnded());
        assertEq(vote.candidatesCount(), 4);
        string[] memory cs = vote.candidates();
        assertEq(cs[0], "Czmil");
        assertEq(cs[1], "Yanisse");
        assertEq(cs[2], "Lilian");
        assertEq(cs[3], "Eckson");
    }

    function testRevert_DeployWithTooFewCandidates() public {
        string[] memory bad = new string[](1);
        bad[0] = "Solo";
        vm.expectRevert(SimpleVote.InvalidCandidatesArray.selector);
        new SimpleVote(bad, owner);
    }

    function testStartVote() public {
        uint256 startTime = block.timestamp;
        uint256 expectedEndTime = startTime + VOTE_DURATION;
        
        vm.expectEmit(true, true, true, true);
        emit VoteStarted(startTime, expectedEndTime, VOTE_DURATION);
        
        vote.startVote(VOTE_DURATION);
        
        assertTrue(vote.voteStarted());
        assertFalse(vote.voteEnded());
        assertEq(vote.voteStartTime(), startTime);
        assertEq(vote.voteEndTime(), expectedEndTime);
        assertTrue(vote.isVotingOpen());
    }

    function testRevert_StartVoteWithZeroDuration() public {
        vm.expectRevert(SimpleVote.InvalidDuration.selector);
        vote.startVote(0);
    }

    function testRevert_StartVoteWithTooLongDuration() public {
        vm.expectRevert(SimpleVote.InvalidDuration.selector);
        vote.startVote(8 days);
    }

    function testRevert_StartVoteTwice() public {
        vote.startVote(VOTE_DURATION);
        vm.expectRevert(SimpleVote.VoteAlreadyStarted.selector);
        vote.startVote(VOTE_DURATION);
    }

    function testRevert_NonOwnerStartVote() public {
        vm.prank(a);
        vm.expectRevert(); // OwnableUnauthorizedAccount
        vote.startVote(VOTE_DURATION);
    }

    function testHappyPath_VoteCounts() public {
        vote.startVote(VOTE_DURATION);
        
        vm.prank(a);
        vote.vote(0); // Czmil
        vm.prank(b);
        vote.vote(2); // Lilian
        vm.prank(c);
        vote.vote(0); // Czmil

        uint256[] memory res = vote.getResults();
        assertEq(res[0], 2); // Czmil
        assertEq(res[1], 0); // Yanisse
        assertEq(res[2], 1); // Lilian
        assertEq(res[3], 0); // Eckson
    }

    function testEvent_Voted() public {
        vote.startVote(VOTE_DURATION);
        
        vm.expectEmit(true, true, true, true);
        emit Voted(a, 1);
        vm.prank(a);
        vote.vote(1);
    }

    function testRevert_VoteBeforeStart() public {
        vm.prank(a);
        vm.expectRevert(SimpleVote.VoteNotStarted.selector);
        vote.vote(0);
    }

    function testRevert_DoubleVote() public {
        vote.startVote(VOTE_DURATION);
        
        vm.prank(a);
        vote.vote(1);
        vm.prank(a);
        vm.expectRevert(SimpleVote.AlreadyVoted.selector);
        vote.vote(2);
    }

    function testRevert_InvalidCandidate_HighIndex() public {
        vote.startVote(VOTE_DURATION);
        
        vm.prank(a);
        vm.expectRevert(SimpleVote.InvalidCandidate.selector);
        vote.vote(999);
    }

    function testVoteAfterTimeExpired() public {
        vote.startVote(VOTE_DURATION);
        
        // Vote normal pendant la période
        vm.prank(a);
        vote.vote(0);
        
        // Avance le temps après la fin du vote
        vm.warp(block.timestamp + VOTE_DURATION + 1);
        
        // Tentative de vote après expiration - DOIT ÉCHOUER
        vm.prank(b);
        vm.expectRevert(SimpleVote.VoteEnded.selector);
        vote.vote(1);
        
        assertFalse(vote.isVotingOpen());
    }

    function testVoteBeforeStartTime() public {
        vote.startVote(VOTE_DURATION);
        
        // Reculer le temps avant le début du vote
        vm.warp(vote.voteStartTime() - 1);
        
        // Tentative de vote avant le début - DOIT ÉCHOUER
        vm.prank(a);
        vm.expectRevert(SimpleVote.VoteNotStarted.selector);
        vote.vote(0);
        
        assertFalse(vote.isVotingOpen());
    }

    function testFinalizeVote() public {
        vote.startVote(VOTE_DURATION);
        
        // Vote pendant la période
        vm.prank(a);
        vote.vote(0);
        
        // Avance le temps après la fin
        vm.warp(block.timestamp + VOTE_DURATION + 1);
        
        // Finalise le vote
        vm.expectEmit(true, true, true, true);
        emit VoteFinalized(vote.voteEndTime());
        vote.finalizeVote();
        
        assertTrue(vote.voteEnded());
        assertFalse(vote.isVotingOpen());
    }

    function testFinalizeVoteBeforeEnd() public {
        vote.startVote(VOTE_DURATION);
        
        // Tentative de finalisation avant la fin
        vote.finalizeVote();
        
        assertFalse(vote.voteEnded());
        assertTrue(vote.isVotingOpen());
    }

    function testGetVoteStatus() public {
        uint256 startTime = block.timestamp;
        vote.startVote(VOTE_DURATION);
        
        (bool started, bool ended, uint256 start, uint256 end, uint256 current, uint256 remaining) = vote.getVoteStatus();
        
        assertTrue(started);
        assertFalse(ended);
        assertEq(start, startTime);
        assertEq(end, startTime + VOTE_DURATION);
        assertEq(current, block.timestamp);
        assertGt(remaining, 0);
        assertLe(remaining, VOTE_DURATION);
    }

    function testGetVoteStatusAfterExpiration() public {
        vote.startVote(VOTE_DURATION);
        vm.warp(block.timestamp + VOTE_DURATION + 1);
        
        (bool started, bool ended, uint256 start, uint256 end, uint256 current, uint256 remaining) = vote.getVoteStatus();
        
        assertTrue(started);
        assertFalse(ended); // Pas encore finalisé
        assertEq(remaining, 0);
    }

    // -------- Fuzz tests --------

    function testFuzz_Vote_IndexBounds(uint256 idx) public {
        vote.startVote(VOTE_DURATION);
        vm.assume(idx > 1000); // hors bornes pour 4 candidats
        vm.prank(a);
        vm.expectRevert(SimpleVote.InvalidCandidate.selector);
        vote.vote(idx);
    }

    function testFuzz_DistinctAddresses_VoteOnce(address x, uint256 pick) public {
        vm.assume(x != address(0));
        vote.startVote(VOTE_DURATION);
        
        uint256 n = vote.candidatesCount();
        pick = pick % n;

        // First vote ok
        vm.prank(x);
        vote.vote(pick);

        // Second vote from same address must revert
        vm.prank(x);
        vm.expectRevert(SimpleVote.AlreadyVoted.selector);
        vote.vote(pick);
    }

    function testFuzz_StartVoteDuration(uint256 duration) public {
        vm.assume(duration > 0 && duration <= 7 days); // Durée raisonnable
        
        vote.startVote(duration);
        
        assertTrue(vote.voteStarted());
        assertEq(vote.voteEndTime(), vote.voteStartTime() + duration);
    }
}
