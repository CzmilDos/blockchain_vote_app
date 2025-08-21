// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {SimpleVote} from "../contracts/SimpleVote.sol";

contract Invariants is Test {
    SimpleVote vote;
    address[] voters;
    uint256 constant VOTE_DURATION = 3600; // 1 heure

    // mapping local pour éviter de tenter plusieurs votes depuis la même adresse
    mapping(address => bool) private seen;

    function setUp() public {
        string[] memory names = new string[](4);
        names[0] = "Czmil";
        names[1] = "Yanisse";
        names[2] = "Lilian";
        names[3] = "Eckson";
        vote = new SimpleVote(names, address(this));

        // IMPORTANT: Le vote ne démarre PAS automatiquement
        // Il faut le démarrer manuellement pour les tests

        // Échantillon d'adresses (peut contenir des doublons -> on gère avec seen[])
        voters = new address[](10);
        for (uint256 i; i < voters.length; ++i) {
            voters[i] = address(uint160(uint256(keccak256(abi.encode(i, blockhash(block.number - 1))))));
        }
    }

    function testInvariant_SumResults_EqualsUniqueVoters() public {
        // Démarre le vote pour ce test
        vote.startVote(VOTE_DURATION);
        
        uint256 n = vote.candidatesCount();

        for (uint256 i; i < voters.length; ++i) {
            address v = voters[i];
            if (seen[v]) continue;            // ne tente pas plusieurs fois
            seen[v] = true;

            // Si l'adresse n'a pas encore voté on-chain et que le vote est ouvert
            if (!vote.hasVoted(v) && vote.isVotingOpen()) {
                vm.prank(v);
                // borne l'index de candidat et vote
                vote.vote(i % n);
            }
        }

        // Somme des voix
        uint256[] memory res = vote.getResults();
        uint256 sum;
        for (uint256 i; i < res.length; ++i) sum += res[i];

        // Compte des électeurs uniques ayant voté (parmi notre échantillon)
        uint256 confirmed;
        for (uint256 i; i < voters.length; ++i) {
            // ne compte chaque adresse qu'une seule fois
            if (seen[voters[i]] && vote.hasVoted(voters[i])) confirmed++;
        }

        assertEq(sum, confirmed, "la somme des voix doit egaler le nb d'electeurs uniques ayant vote");
    }

    function testInvariant_VoteStateConsistency() public {
        // Test sans vote démarré
        bool isOpen = vote.isVotingOpen();
        bool started = vote.voteStarted();
        bool ended = vote.voteEnded();
        
        assertFalse(started, "le vote ne doit pas etre demarre initialement");
        assertFalse(ended, "le vote ne doit pas etre termine initialement");
        assertFalse(isOpen, "le vote ne doit pas etre ouvert initialement");
        
        // Démarre le vote
        vote.startVote(VOTE_DURATION);
        
        // Vérifie la cohérence des états du vote
        isOpen = vote.isVotingOpen();
        started = vote.voteStarted();
        ended = vote.voteEnded();
        
        if (started && !ended) {
            // Si le vote a commencé mais pas fini, vérifie les timestamps
            uint256 currentTime = block.timestamp;
            uint256 startTime = vote.voteStartTime();
            uint256 endTime = vote.voteEndTime();
            
            assertGe(currentTime, startTime, "le temps actuel doit etre >= au temps de debut");
            assertLe(currentTime, endTime, "le temps actuel doit etre <= au temps de fin");
            assertTrue(isOpen, "le vote doit etre ouvert si dans la fenetre temporelle");
        } else if (ended) {
            assertFalse(isOpen, "le vote ne doit pas etre ouvert s'il est termine");
        }
    }
}
