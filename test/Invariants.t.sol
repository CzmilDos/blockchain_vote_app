// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {SimpleVote} from "../contracts/SimpleVote.sol";

contract Invariants is Test {
    SimpleVote vote;
    address[] voters;

    // mapping local pour éviter de tenter plusieurs votes depuis la même adresse
    mapping(address => bool) private seen;

    function setUp() public {
        string;
        names[0] = "Alice";
        names[1] = "Bob";
        names[2] = "Charlie";
        vote = new SimpleVote(names, address(this));

        // Échantillon d'adresses (peut contenir des doublons -> on gère avec seen[])
        voters = new address;
        for (uint256 i; i < voters.length; ++i) {
            voters[i] = address(uint160(uint256(keccak256(abi.encode(i, blockhash(block.number - 1))))));
        }
    }

    function testInvariant_SumResults_EqualsUniqueVoters() public {
        uint256 n = vote.candidatesCount();

        for (uint256 i; i < voters.length; ++i) {
            address v = voters[i];
            if (seen[v]) continue;            // ne tente pas plusieurs fois
            seen[v] = true;

            // Si l'adresse n'a pas encore voté on-chain, on vote
            if (!vote.hasVoted(v)) {
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
}
