// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

import "../../common/Enum.sol";
import "../../base/GuardManager.sol";
import "../../GnosisSafe.sol";

/// @title Debug Transaction Guard - A guard that will emit events with extended information.
/// @notice This guard is only meant as a development tool and example
/// @author Richard Meissner - <richard@gnosis.pm>
contract InternetNativeCompanyGuard is BaseGuard {
    // solhint-disable-next-line payable-fallback
    fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        // solhint-disable-next-line no-unused-vars
        address payable refundReceiver,
        bytes memory,
        address
    ) external override {}

    function checkAfterExecution(bytes32 txHash, bool success) external override {}
}
