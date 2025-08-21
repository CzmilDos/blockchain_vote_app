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
        string[] memory names = new string[](3);
        names[0] = "Alice";
        names[1] = "Bob";
        names[2] = "Charlie";

        vm.startBroadcast(pk);
        SimpleVote vote = new SimpleVote(names, owner);
        vm.stopBroadcast();

        console2.log("SimpleVote deployed at:", address(vote));
        console2.log("Owner:", owner);
    }
}
