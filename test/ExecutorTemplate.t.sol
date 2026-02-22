// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Test } from "forge-std/Test.sol";
import { RhinestoneModuleKit, ModuleKitHelpers, AccountInstance } from "modulekit/ModuleKit.sol";
import { MODULE_TYPE_EXECUTOR } from "modulekit/accounts/common/interfaces/IERC7579Module.sol";
import { ExecutionLib } from "modulekit/accounts/erc7579/lib/ExecutionLib.sol";
import { ExecutorTemplate } from "src/ExecutorTemplate.sol";

contract ExecutorTemplateTest is RhinestoneModuleKit, Test {
    using ModuleKitHelpers for *;

    // account and modules
    AccountInstance internal instance;
    ExecutorTemplate internal executor;
    address pool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function setUp() public {
        init();

        // Create the executor
        executor = new ExecutorTemplate();
        vm.label(address(executor), "ExecutorTemplate");

        // Create the account and install the executor
        instance = makeAccountInstance("ExecutorTemplate");
        vm.deal(address(instance.account), 10 ether);
        instance.installModule({
            moduleTypeId: MODULE_TYPE_EXECUTOR,
            module: address(executor),
            data: abi.encode(pool, WETH, USDC)
        });
    }

    function testOnInstall() view public {
        assertEq(executor.pool(), pool);
        assertEq(executor.asset0(), WETH);
        assertEq(executor.asset1(), USDC);
    }

    function testExec() public {
        // Create a target address and send some ether to it
        address target = makeAddr("target");
        uint256 value = 1 ether;

        // Get the current balance of the target
        uint256 prevBalance = target.balance;

        // Encode the execution data sent to the account
        bytes memory callData = ExecutionLib.encodeSingle(target, value, "");

        // Execute the call
        // EntryPoint -> Account -> Executor -> Account -> Target
        instance.exec({
            target: address(executor),
            value: 0,
            callData: abi.encodeWithSelector(ExecutorTemplate.execute.selector, callData)
        });

        // Check if the balance of the target has increased
        assertEq(target.balance, prevBalance + value);
    }
}
