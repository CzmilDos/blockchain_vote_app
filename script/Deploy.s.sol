// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {SimpleVote} from "../contracts/SimpleVote.sol";

/// @title Script de deploiement pour SimpleVote
/// @dev Deploiement optimise avec logs informatifs
/// @author Votre nom
contract DeployScript is Script {
    function run() external {
        // ======== Setup ========
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        
        // ======== Configuration ========
        string[] memory candidates = new string[](4);
        candidates[0] = "Czmil";
        candidates[1] = "Yanisse";
        candidates[2] = "Lilian";
        candidates[3] = "Eckson";
        
        console2.log("Deploiement SimpleVote");
        console2.log("Deployeur:", deployer);
        console2.log("Candidats:", candidates.length);
        
        // ======== Deploiement ========
        vm.startBroadcast(deployerKey);
        
        SimpleVote voteContract = new SimpleVote(candidates, deployer);
        
        vm.stopBroadcast();
        
        // ======== Verification ========
        console2.log("Contrat deploye a:", address(voteContract));
        console2.log("Owner:", voteContract.owner());
        console2.log("Nombre de candidats:", voteContract.candidatesCount());
        
        // ======== Etat initial ========
        console2.log("Etat initial:");
        console2.log("   Vote demarre:", voteContract.voteStarted());
        console2.log("   Vote termine:", voteContract.voteEnded());
        console2.log("   Vote ouvert:", voteContract.isVotingOpen());
        
        // ======== Instructions ========
        console2.log("Instructions:");
        console2.log("   1. Connectez-vous a l'interface web");
        console2.log("   2. Chargez le contrat avec l'adresse ci-dessus");
        console2.log("   3. En tant qu'owner, demarrez le vote avec une duree");
        console2.log("   4. Les utilisateurs peuvent alors voter");
        
        console2.log("Deploiement termine avec succes!");
    }
}
