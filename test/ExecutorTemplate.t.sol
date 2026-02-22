// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {RhinestoneModuleKit, ModuleKitHelpers, AccountInstance} from "modulekit/ModuleKit.sol";
import {MODULE_TYPE_EXECUTOR} from "modulekit/accounts/common/interfaces/IERC7579Module.sol";
import {ExecutionLib} from "modulekit/accounts/erc7579/lib/ExecutionLib.sol";
import {ExecutorTemplate} from "src/ExecutorTemplate.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

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

    function testOnInstall() public view {
        assertEq(executor.pool(), pool);
        assertEq(executor.asset0(), WETH);
        assertEq(executor.asset1(), USDC);
    }

    function testExec() public {
        deal(WETH, address(instance.account), 10 ether);
        // Encode the execution data sent to the account

        // bytes memory supplyData = abi.encodeWithSignature(
        //     "supply(address, uint256, address, uint16)",
        //     WETH,
        //     10 ether,
        //     address(this),
        //     0
        // );
        instance.exec({
            target: address(executor),
            value: 0,
            callData: abi.encodeWithSelector(
                ExecutorTemplate.execute.selector,
                "0x"
            )
        });
        assertEq(
            IERC20(WETH).allowance(address(executor), pool),
            10 ether
        );
    }
}
