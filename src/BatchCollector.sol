// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {AccessControl} from "@openzeppelin-contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

contract BatchCollector is AccessControl {
    /// @notice SafeERC20 library for safe token transfers
    using SafeERC20 for IERC20;

    /// @notice Manager role
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// @notice Error for mismatched array lengths
    error ArrayLengthsMismatch();

    /// @notice Error for zero destination address
    error ZeroDestinationAddressNotAllowed();

    /// @notice Error for zero token address
    error ZeroTokenAddressNotAllowed();

    /// @notice Error for zero source address
    error ZeroSourceAddressNotAllowed();

    /// @notice Error for zero amount
    error ZeroAmountNotAllowed();

    /// @notice Batch collected event
    /// @param sources Array of source addresses
    /// @param tokens Array of token addresses
    /// @param amounts Array of amounts
    /// @param destinations Array of destination addresses
    /// @param executor Address of executor
    event BatchCollected(
        address[] sources, IERC20[] tokens, uint256[] amounts, address[] destinations, address executor
    );

    /// @notice Constructor
    /// @param initialAdmin Initial admin address
    /// @param initialManager Initial manager address
    constructor(address initialAdmin, address initialManager) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(MANAGER_ROLE, initialManager);
    }

    /// @notice Batch collect function
    /// @param sources Array of source addresses
    /// @param tokens Array of token addresses
    /// @param amounts Array of amounts
    /// @param destinations Array of destination addresses
    function batchCollect(
        address[] calldata sources,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address[] calldata destinations
    ) external onlyRole(MANAGER_ROLE) {
        if (sources.length != tokens.length || tokens.length != amounts.length || amounts.length != destinations.length)
        {
            revert ArrayLengthsMismatch();
        }

        for (uint256 i = 0; i < sources.length; i++) {
            if (sources[i] == address(0)) revert ZeroSourceAddressNotAllowed();
            if (address(tokens[i]) == address(0)) {
                revert ZeroTokenAddressNotAllowed();
            }
            if (amounts[i] == 0) revert ZeroAmountNotAllowed();
            if (destinations[i] == address(0)) {
                revert ZeroDestinationAddressNotAllowed();
            }

            tokens[i].safeTransferFrom(sources[i], destinations[i], amounts[i]);

            emit BatchCollected(sources, tokens, amounts, destinations, msg.sender);
        }
    }
}
