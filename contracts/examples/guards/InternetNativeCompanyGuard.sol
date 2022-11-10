// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

import "../../common/Enum.sol";
import "../../base/GuardManager.sol";
import "../../GnosisSafe.sol";
import "hardhat/console.sol";
import "openzeppelin4/access/Ownable.sol";

/// @title Debug Transaction Guard - A guard that will emit events with extended information.
/// @notice This guard is only meant as a development tool and example
/// @author Richard Meissner - <richard@gnosis.pm>
contract InternetNativeCompanyGuard is Ownable, BaseGuard {

    event SetPropertiesOnTarget(
        address target,
        bool allowed,
        bool scoped,
        bool delegateCallAllowed,
        bool fallbackAllowed,
        bool valueAllowed
    );
    event SetFunctionAllowedOnTarget(
        address target,
        bytes4 functionSig,
        bool allowed
    );

    struct Target {
        bool allowed;
        bool scoped;
        bool delegateCallAllowed;
        bool fallbackAllowed;
        bool valueAllowed;
        mapping(bytes4 => bool) allowedFunctions;
    }

    mapping(address => Target) public allowedTargets;
    mapping(address => bool) public unlockedSafe;

    function setTargetProperties(address target, bool allow, bool scope, bool delegateCallAllow, bool fallbackAllow, bool valueAllow) public onlyOwner {
        allowedTargets[target].allowed = allow;
        allowedTargets[target].scoped = scope;
        allowedTargets[target].delegateCallAllowed = delegateCallAllow;
        allowedTargets[target].fallbackAllowed = fallbackAllow;
        allowedTargets[target].valueAllowed = valueAllow;
        emit SetPropertiesOnTarget(
          target,
          allowedTargets[target].allowed,
          allowedTargets[target].scoped,
          allowedTargets[target].delegateCallAllowed,
          allowedTargets[target].fallbackAllowed,
          allowedTargets[target].valueAllowed
        );
    }

    function setAllowedFunction(
        address target,
        bytes4 functionSig,
        bool allow
    ) public onlyOwner {
        allowedTargets[target].allowedFunctions[functionSig] = allow;
        emit SetFunctionAllowedOnTarget(
            target,
            functionSig,
            allowedTargets[target].allowedFunctions[functionSig]
        );
    }

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
        uint256,
        uint256,
        uint256,
        address,
        // solhint-disable-next-line no-unused-vars
        address payable refundReceiver,
        bytes memory,
        address
    ) external override {
        console.log("safe address is msg.sender:", msg.sender);
        if (unlockedSafe[msg.sender]) {
          return();
        }
        (bool success, bytes memory result) = msg.sender.call(abi.encodeWithSignature("getThreshold()"));
        require(success, "You should be able to succesfully get the safe threshold");
        (uint _threshold) = abi.decode(result, (uint));
        console.log("current safe threshold:", _threshold);
        if (_threshold > 1) {
          return();
        }
        require(
            operation != Enum.Operation.DelegateCall ||
                allowedTargets[to].delegateCallAllowed,
            "Delegate call not allowed to this address"
        );
        require(allowedTargets[to].allowed, "Target address is not allowed");
        if (value > 0) {
            require(
                allowedTargets[to].valueAllowed,
                "Cannot send ETH to this target"
            );
        }
        if (data.length >= 4) {
            require(
                !allowedTargets[to].scoped ||
                    allowedTargets[to].allowedFunctions[bytes4(data)],
                "Target function is not allowed"
            );
        } else {
            require(data.length == 0, "Function signature too short");
            require(
                !allowedTargets[to].scoped ||
                    allowedTargets[to].fallbackAllowed,
                "Fallback not allowed for this address"
            );
        }
    }

    function checkAfterExecution(bytes32 txHash, bool success) external override {}
}
