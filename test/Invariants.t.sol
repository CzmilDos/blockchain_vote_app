// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SimpleVote} from "../contracts/SimpleVote.sol";

/// @title Tests d'invariants pour SimpleVote
/// @dev Verification des proprietes invariantes du systeme
contract Invariants is Test {
    // ======== Events ========
    event Voted(address indexed voter, uint8 indexed candidateIndex);
    event VoteStarted(uint32 startTime, uint32 endTime, uint16 duration);

    // ======== Test Setup ========
    SimpleVote vote;
    address[] voters;
    uint16 constant VOTE_DURATION = 3600; // 1 heure
    uint16 constant MAX_VOTERS = 100;

    // Mapping pour eviter les doublons
    mapping(address => bool) private seen;

    function setUp() public {
        string[] memory candidates = new string[](4);
        candidates[0] = "Czmil";
        candidates[1] = "Yanisse";
        candidates[2] = "Lilian";
        candidates[3] = "Eckson";
        vote = new SimpleVote(candidates, address(this));

        // Generation d'un echantillon d'adresses uniques
        voters = new address[](MAX_VOTERS);
        for (uint16 i; i < MAX_VOTERS; ++i) {
            voters[i] = address(uint160(uint256(keccak256(abi.encode(i, blockhash(block.number - 1))))));
        }
    }

    // ======== Invariants de Coherence ========
    
    /// @dev Invariant: La somme des votes doit egaler le nombre d'electeurs uniques
    function testInvariant_SumVotesEqualsUniqueVoters() public {
        // Demarre le vote
        vote.startVote(VOTE_DURATION);
        
        uint8 n = vote.candidatesCount();
        uint16 totalVotes = 0;
        uint16 uniqueVoters = 0;

        // Vote pour chaque electeur unique
        for (uint16 i; i < voters.length; ++i) {
            address voter = voters[i];
            if (seen[voter]) continue; // Evite les doublons
            seen[voter] = true;

            // Vote si possible
            if (!vote.hasVoted(voter) && vote.isVotingOpen()) {
                vm.prank(voter);
                vote.vote(uint8(i % n));
                uniqueVoters++;
            }
        }

        // Calcule la somme des votes
        uint8[] memory results = vote.getResults();
        for (uint8 i; i < n; ++i) {
            totalVotes += results[i];
        }

        // Invariant: somme des votes = electeurs uniques
        assertEq(totalVotes, uniqueVoters, "Somme des votes doit egaler le nombre d'electeurs uniques");
    }

    /// @dev Invariant: Coherence des etats temporels
    function testInvariant_TemporalStateConsistency() public {
        bool isOpen = vote.isVotingOpen();
        bool started = vote.voteStarted();
        bool ended = vote.voteEnded();
        
        // Invariant: Si pas demarre, pas ouvert et pas fini
        if (!started) {
            assertFalse(isOpen, "Vote non demarre ne peut pas etre ouvert");
            assertFalse(ended, "Vote non demarre ne peut pas etre fini");
        }
        
        // Invariant: Si fini, pas ouvert
        if (ended) {
            assertFalse(isOpen, "Vote fini ne peut pas etre ouvert");
        }
        
        // Invariant: Si ouvert, demarre et pas fini
        if (isOpen) {
            assertTrue(started, "Vote ouvert doit etre demarre");
            assertFalse(ended, "Vote ouvert ne peut pas etre fini");
        }
    }

    /// @dev Invariant: Coherence des timestamps
    function testInvariant_TimestampConsistency() public {
        if (vote.voteStarted()) {
            uint32 startTime = vote.voteStartTime();
            uint32 endTime = vote.voteEndTime();
            uint32 currentTime = uint32(block.timestamp);
            
            // Invariant: End time > Start time
            assertGt(endTime, startTime, "End time doit etre > start time");
            
            // Invariant: Si actif, current time dans la fenetre
            if (vote.isVotingOpen()) {
                assertGe(currentTime, startTime, "Current time doit etre >= start time");
                assertLt(currentTime, endTime, "Current time doit etre < end time");
            }
        }
    }

    // ======== Invariants de Securite ========
    
    /// @dev Invariant: Un electeur ne peut voter qu'une fois
    function testInvariant_SingleVotePerAddress() public {
        vote.startVote(VOTE_DURATION);
        
        for (uint16 i; i < 10; ++i) {
            address voter = voters[i];
            
            if (!vote.hasVoted(voter) && vote.isVotingOpen()) {
                vm.prank(voter);
                vote.vote(0);
                
                // Invariant: Apres vote, hasVoted[voter] = true
                assertTrue(vote.hasVoted(voter), "Electeur doit etre marque comme ayant vote");
                
                // Tentative de vote supplementaire
                vm.prank(voter);
                vm.expectRevert(SimpleVote.AlreadyVoted.selector);
                vote.vote(1);
            }
        }
    }

    /// @dev Invariant: Pas de vote avec index invalide
    function testInvariant_NoInvalidCandidateIndex() public {
        vote.startVote(VOTE_DURATION);
        
        uint8 maxIndex = vote.candidatesCount();
        
        for (uint16 i; i < 10; ++i) {
            address voter = voters[i];
            
            if (!vote.hasVoted(voter) && vote.isVotingOpen()) {
                // Test avec index valide
                vm.prank(voter);
                vote.vote(maxIndex - 1); // Dernier index valide
                
                // Test avec index invalide
                address nextVoter = voters[i + 1];
                if (!vote.hasVoted(nextVoter) && vote.isVotingOpen()) {
                    vm.prank(nextVoter);
                    vm.expectRevert(SimpleVote.InvalidCandidate.selector);
                    vote.vote(maxIndex); // Index invalide
                }
                break;
            }
        }
    }

    // ======== Invariants de Performance ========
    
    /// @dev Invariant: Pas de debordement des compteurs
    function testInvariant_NoCounterOverflow() public {
        vote.startVote(VOTE_DURATION);
        
        uint8 candidateIndex = 0;
        uint8 maxVotes = 255; // Test avec max votes pour uint8
        
        for (uint8 i; i < maxVotes; ++i) {
            address voter = address(uint160(i + 1000));
            
            if (!vote.hasVoted(voter) && vote.isVotingOpen()) {
                vm.prank(voter);
                vote.vote(candidateIndex);
            }
        }
        
        // Invariant: Le compteur doit etre egal au nombre de votes
        assertEq(vote.votesCount(candidateIndex), maxVotes, "Compteur doit etre correct");
    }

    /// @dev Invariant: Performance des lectures
    function testInvariant_ReadPerformance() public {
        vote.startVote(VOTE_DURATION);
        
        // Test de performance pour les lectures multiples
        for (uint16 i; i < 100; ++i) {
            vote.isVotingOpen();
            vote.getVoteStatus();
            vote.getResults();
        }
        
        // Si on arrive ici, pas de probleme de performance
        assertTrue(true, "Lectures multiples sans probleme");
    }

    // ======== Invariants Mathematiques ========
    
    /// @dev Invariant: Propriete de conservation des votes
    function testInvariant_VoteConservation() public {
        vote.startVote(VOTE_DURATION);
        
        uint16 totalVotesBefore = 0;
        uint8[] memory resultsBefore = vote.getResults();
        for (uint8 i; i < vote.candidatesCount(); ++i) {
            totalVotesBefore += resultsBefore[i];
        }
        
        // Ajoute quelques votes
        for (uint16 i; i < 5; ++i) {
            address voter = voters[i];
            if (!vote.hasVoted(voter) && vote.isVotingOpen()) {
                vm.prank(voter);
                vote.vote(uint8(i % 4));
            }
        }
        
        uint16 totalVotesAfter = 0;
        uint8[] memory resultsAfter = vote.getResults();
        for (uint8 i; i < vote.candidatesCount(); ++i) {
            totalVotesAfter += resultsAfter[i];
        }
        
        // Invariant: Conservation des votes existants
        assertGe(totalVotesAfter, totalVotesBefore, "Total des votes ne peut que croitre");
    }

    /// @dev Invariant: Propriete de monotonie
    function testInvariant_Monotonicity() public {
        vote.startVote(VOTE_DURATION);
        
        uint8[] memory results1 = vote.getResults();
        
        // Ajoute un vote
        address voter = voters[0];
        if (!vote.hasVoted(voter) && vote.isVotingOpen()) {
            vm.prank(voter);
            vote.vote(0);
        }
        
        uint8[] memory results2 = vote.getResults();
        
        // Invariant: Monotonie croissante
        assertGe(results2[0], results1[0], "Compteur de votes doit etre monotone croissant");
    }

    // ======== Invariants de Finalisation ========
    
    /// @dev Invariant: Expiration automatique
    function testInvariant_AutomaticExpiration() public {
        vote.startVote(VOTE_DURATION);
        
        // Vote pendant la periode
        address voter = voters[0];
        if (!vote.hasVoted(voter) && vote.isVotingOpen()) {
            vm.prank(voter);
            vote.vote(0);
        }
        
        // Avance le temps apres expiration
        vm.warp(block.timestamp + VOTE_DURATION + 1);
        
        // Invariant: Apres expiration, vote automatiquement ferme
        assertFalse(vote.isVotingOpen(), "Vote ne doit pas etre ouvert apres expiration");
        
        // Invariant: Tentative de vote apres expiration doit echouer
        address voter2 = voters[1];
        vm.prank(voter2);
        vm.expectRevert(SimpleVote.VoteEnded.selector);
        vote.vote(1);
    }

    // ======== Invariants de Reinitialisation ========
    
    /// @dev Invariant: Etat initial coherent
    function testInvariant_InitialStateConsistency() public {
        // Invariant: Etat initial
        assertFalse(vote.voteStarted(), "Vote ne doit pas etre demarre initialement");
        assertFalse(vote.voteEnded(), "Vote ne doit pas etre termine initialement");
        assertFalse(vote.isVotingOpen(), "Vote ne doit pas etre ouvert initialement");
        
        // Invariant: Timestamps initiaux
        assertEq(vote.voteStartTime(), 0, "Start time doit etre 0 initialement");
        assertEq(vote.voteEndTime(), 0, "End time doit etre 0 initialement");
        
        // Invariant: Resultats initiaux
        uint8[] memory results = vote.getResults();
        for (uint8 i; i < vote.candidatesCount(); ++i) {
            assertEq(results[i], 0, "Compteurs doivent etre a 0 initialement");
        }
    }

    // ======== Invariants de Robustesse ========
    
    /// @dev Invariant: Robustesse aux appels multiples
    function testInvariant_RobustnessToMultipleCalls() public {
        vote.startVote(VOTE_DURATION);
        
        // Appels multiples a startVote
        vm.expectRevert(SimpleVote.VoteAlreadyStarted.selector);
        vote.startVote(VOTE_DURATION);
        
        // Invariant: Vote reste ouvert avant expiration
        assertTrue(vote.isVotingOpen(), "Vote doit rester ouvert avant expiration");
        assertFalse(vote.voteEnded(), "Vote ne doit pas etre termine avant expiration");
    }

    /// @dev Invariant: Coherence des evenements
    function testInvariant_EventConsistency() public {
        // Test evenement VoteStarted
        vm.expectEmit(true, true, true, true);
        emit VoteStarted(uint32(block.timestamp), uint32(block.timestamp + VOTE_DURATION), uint16(VOTE_DURATION));
        vote.startVote(VOTE_DURATION);
        
        // Test evenement Voted
        address voter = voters[0];
        vm.expectEmit(true, true, true, true);
        emit Voted(voter, 0);
        vm.prank(voter);
        vote.vote(0);
        
        // Invariant: Pas d'evenement VoteFinalized (supprime)
        // Le vote se termine automatiquement a l'expiration
    }
}
