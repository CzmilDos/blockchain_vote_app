// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {SimpleVote} from "../contracts/SimpleVote.sol";

contract SimpleVoteTest is Test {
    // Re-déclare l'évènement pour expectEmit
    event Voted(address indexed voter, uint256 indexed candidateIndex);

    SimpleVote vote;
    address owner;
    address a = address(0xA1);
    address b = address(0xB2);
    address c = address(0xC3);

    string[] names;

    function setUp() public {
        owner = address(this);
        names = new string[](3);
        names[0] = "Alice";
        names[1] = "Bob";
        names[2] = "Charlie";
        vote = new SimpleVote(names, owner);
    }

    function testInitialState() public {
        assertTrue(vote.votingOpen());
        assertEq(vote.candidatesCount(), 3);
        string[] memory cs = vote.candidates();
        assertEq(cs[0], "Alice");
    }

    function testRevert_DeployWithTooFewCandidates() public {
        string[] memory bad = new string[](1);
        bad[0] = "Solo";
        vm.expectRevert(SimpleVote.InvalidCandidatesArray.selector);
        new SimpleVote(bad, owner);
    }

    function testHappyPath_VoteCounts() public {
        vm.prank(a);
        vote.vote(0); // Alice
        vm.prank(b);
        vote.vote(2); // Charlie
        vm.prank(c);
        vote.vote(0); // Alice

        uint256[] memory res = vote.getResults();
        assertEq(res[0], 2); // Alice
        assertEq(res[1], 0); // Bob
        assertEq(res[2], 1); // Charlie
    }

    function testEvent_Voted() public {
        vm.expectEmit(true, true, true, true);
        emit Voted(a, 1);
        vm.prank(a);
        vote.vote(1);
    }

    function testRevert_DoubleVote() public {
        vm.prank(a);
        vote.vote(1);
        vm.prank(a);
        vm.expectRevert(SimpleVote.AlreadyVoted.selector);
        vote.vote(2);
    }

    function testRevert_InvalidCandidate_HighIndex() public {
        vm.prank(a);
        vm.expectRevert(SimpleVote.InvalidCandidate.selector);
        vote.vote(999);
    }

    function testOpenCloseVoting() public {
        // Close
        vote.closeVoting();
        assertFalse(vote.votingOpen());

        // Can't vote when closed
        vm.prank(a);
        vm.expectRevert(SimpleVote.ErrVotingClosed.selector);
        vote.vote(0);

        // Reopen
        vote.openVoting();
        assertTrue(vote.votingOpen());

        // Vote works again, but still one vote per address
        vm.prank(a);
        vote.vote(0);
        vm.prank(a);
        vm.expectRevert(SimpleVote.AlreadyVoted.selector);
        vote.vote(0);
    }

    function testOwnerOnly_OpenClose() public {
        // Non-owner cannot close
        vm.prank(a);
        vm.expectRevert(); // OwnableUnauthorizedAccount
        vote.closeVoting();

        // Owner can close
        vote.closeVoting();
        assertFalse(vote.votingOpen());

        // Non-owner cannot open
        vm.prank(a);
        vm.expectRevert(); // OwnableUnauthorizedAccount
        vote.openVoting();

        // Owner can open
        vote.openVoting();
        assertTrue(vote.votingOpen());
    }

    // -------- Fuzz tests --------

    function testFuzz_Vote_IndexBounds(uint256 idx) public {
        vm.assume(idx > 1000); // hors bornes pour 3 candidats
        vm.prank(a);
        vm.expectRevert(SimpleVote.InvalidCandidate.selector);
        vote.vote(idx);
    }

    function testFuzz_DistinctAddresses_VoteOnce(address x, uint256 pick) public {
        vm.assume(x != address(0));
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
}
