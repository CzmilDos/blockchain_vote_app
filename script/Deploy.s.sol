// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {SimpleVote} from "../contracts/SimpleVote.sol";

contract Deploy is Script {
    function run() external {
        // Ex.: export PRIVATE_KEY=0xabc... (clé de démo/anvil)
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(pk);

        // Prépare la liste des candidats (modifiable pour ta démo)
        string[] memory names = new string[](4);
        names[0] = "Czmil";
        names[1] = "Yanisse";
        names[2] = "Lilian";
        names[3] = "Eckson";

        vm.startBroadcast(pk);
        SimpleVote vote = new SimpleVote(names, owner);
        // IMPORTANT: Le vote ne démarre PAS automatiquement
        // L'owner devra le démarrer manuellement via l'interface web
        vm.stopBroadcast();

        console2.log("SimpleVote deployed at:", address(vote));
        console2.log("Owner:", owner);
        console2.log("IMPORTANT: Le vote n'est PAS demarre automatiquement");
        console2.log("L'owner doit demarrer le vote manuellement via l'interface web");
    }
}
