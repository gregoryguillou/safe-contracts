// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

import "../../common/Enum.sol";
import "../../base/GuardManager.sol";
import "../../GnosisSafe.sol";
import "hardhat/console.sol";

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
        bytes memory signatures,
        address msgSender
    ) external override {
          console.log("safe address is msg.sender:", msg.sender);
          console.log("signatures are:");
          console.logBytes(signatures); 
          (bool success, bytes memory result) = msg.sender.call(abi.encodeWithSignature("getThreshold()"));
          require(success, "You should be able to succesfully get the safe threshold");
          (uint _threshold) = abi.decode(result, (uint));
          console.log("current safe threshold:", _threshold);
          require(_threshold > 1, "You must have at least 2 signers to execute a transaction");
    }

    function checkAfterExecution(bytes32 txHash, bool success) external override {}
}
