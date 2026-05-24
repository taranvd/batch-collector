// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {BatchCollector} from "../src/BatchCollector.sol";
import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin-contracts/token/ERC20/ERC20.sol";
import {IAccessControl} from "@openzeppelin-contracts/access/IAccessControl.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock", "MCK") {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract BatchCollectorTest is Test {
    BatchCollector public collector;
    MockERC20 public token1;
    MockERC20 public token2;

    address public admin = makeAddr("admin");
    address public manager = makeAddr("manager");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    address public dest1 = makeAddr("dest1");
    address public dest2 = makeAddr("dest2");

    event BatchCollected(
        address[] sources, IERC20[] tokens, uint256[] amounts, address[] destinations, address executor
    );

    function setUp() public {
        collector = new BatchCollector(admin, manager);
        token1 = new MockERC20();
        token2 = new MockERC20();
    }

    function test_InitialRoles() public {
        assertTrue(collector.hasRole(collector.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(collector.hasRole(collector.MANAGER_ROLE(), manager));
    }

    function testRevert_AccessControl() public {
        address[] memory sources = new address[](1);
        IERC20[] memory tokens = new IERC20[](1);
        uint256[] memory amounts = new uint256[](1);
        address[] memory destinations = new address[](1);

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, collector.MANAGER_ROLE())
        );
        vm.prank(alice);
        collector.batchCollect(sources, tokens, amounts, destinations);
    }

    function testRevert_ArrayLengthsMismatch() public {
        address[] memory sources = new address[](2);
        IERC20[] memory tokens = new IERC20[](1);
        uint256[] memory amounts = new uint256[](1);
        address[] memory destinations = new address[](1);

        vm.prank(manager);
        vm.expectRevert(BatchCollector.ArrayLengthsMismatch.selector);
        collector.batchCollect(sources, tokens, amounts, destinations);
    }

    function testRevert_ZeroSourceAddressNotAllowed() public {
        address[] memory sources = new address[](1);
        sources[0] = address(0);
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(address(token1));
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;
        address[] memory destinations = new address[](1);
        destinations[0] = dest1;

        vm.prank(manager);
        vm.expectRevert(BatchCollector.ZeroSourceAddressNotAllowed.selector);
        collector.batchCollect(sources, tokens, amounts, destinations);
    }

    function testRevert_ZeroTokenAddressNotAllowed() public {
        address[] memory sources = new address[](1);
        sources[0] = alice;
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(address(0));
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;
        address[] memory destinations = new address[](1);
        destinations[0] = dest1;

        vm.prank(manager);
        vm.expectRevert(BatchCollector.ZeroTokenAddressNotAllowed.selector);
        collector.batchCollect(sources, tokens, amounts, destinations);
    }

    function testRevert_ZeroAmountNotAllowed() public {
        address[] memory sources = new address[](1);
        sources[0] = alice;
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(address(token1));
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        address[] memory destinations = new address[](1);
        destinations[0] = dest1;

        vm.prank(manager);
        vm.expectRevert(BatchCollector.ZeroAmountNotAllowed.selector);
        collector.batchCollect(sources, tokens, amounts, destinations);
    }

    function testRevert_ZeroDestinationAddressNotAllowed() public {
        address[] memory sources = new address[](1);
        sources[0] = alice;
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(address(token1));
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;
        address[] memory destinations = new address[](1);
        destinations[0] = address(0);

        vm.prank(manager);
        vm.expectRevert(BatchCollector.ZeroDestinationAddressNotAllowed.selector);
        collector.batchCollect(sources, tokens, amounts, destinations);
    }

    function test_BatchCollect_Single() public {
        token1.mint(alice, 1000);
        
        vm.prank(alice);
        token1.approve(address(collector), 1000);

        address[] memory sources = new address[](1);
        sources[0] = alice;
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IERC20(address(token1));
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;
        address[] memory destinations = new address[](1);
        destinations[0] = dest1;

        vm.expectEmit(true, true, true, true);
        emit BatchCollected(sources, tokens, amounts, destinations, manager);

        vm.prank(manager);
        collector.batchCollect(sources, tokens, amounts, destinations);

        assertEq(token1.balanceOf(alice), 900);
        assertEq(token1.balanceOf(dest1), 100);
    }

    function test_BatchCollect_Multiple() public {
        token1.mint(alice, 1000);
        token2.mint(bob, 500);
        
        vm.prank(alice);
        token1.approve(address(collector), 1000);

        vm.prank(bob);
        token2.approve(address(collector), 500);

        address[] memory sources = new address[](2);
        sources[0] = alice;
        sources[1] = bob;

        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = IERC20(address(token1));
        tokens[1] = IERC20(address(token2));

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 200;
        amounts[1] = 300;

        address[] memory destinations = new address[](2);
        destinations[0] = dest1;
        destinations[1] = dest2;

        vm.prank(manager);
        collector.batchCollect(sources, tokens, amounts, destinations);

        assertEq(token1.balanceOf(alice), 800);
        assertEq(token1.balanceOf(dest1), 200);

        assertEq(token2.balanceOf(bob), 200);
        assertEq(token2.balanceOf(dest2), 300);
    }
}
