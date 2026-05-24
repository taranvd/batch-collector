// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {BatchCollector} from "../src/BatchCollector.sol";

contract DeployBatchCollector is Script {
    address public admin;
    address public manager;

    function run() external returns (BatchCollector collector) {
        admin = vm.envAddress("ADMIN_ADDRESS");
        manager = vm.envAddress("MANAGER_ADDRESS");

        console.log("Deploying BatchCollector...");
        console.log("  Admin:   ", admin);
        console.log("  Manager: ", manager);

        vm.startBroadcast();

        collector = new BatchCollector(admin, manager);

        vm.stopBroadcast();

        console.log("BatchCollector deployed at:", address(collector));
    }
}
