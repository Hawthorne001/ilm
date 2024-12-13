// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import { Script } from "forge-std/Script.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DeployHelper } from "../DeployHelper.s.sol";
import { WrappedERC20PermissionedDeposit } from
    "../../../src/tokens/WrappedERC20PermissionedDeposit.sol";
import { ERC20Config } from "../config/LoopStrategyConfig.sol";

contract WrappedweETHConfig {
    ERC20Config public wrappedweETHERC20Config =
        ERC20Config({ name: "Seamless ILM Reserved weETH", symbol: "rweETH" });
}

/// @title DeployWrappedweETH
/// @notice deploys and setup Seamless wrapped weETH token
/// @notice gives admin roles to the SEAMLESS_GOV_SHORT_TIMELOCK_ADDRESS and SEAMLESS_COMMUNITY_MULTISIG
contract DeployWrappedweETH is Script, DeployHelper, WrappedweETHConfig {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        WrappedERC20PermissionedDeposit wrappedToken = _deployWrappedToken(
            deployerAddress, wrappedweETHERC20Config, IERC20(BASE_MAINNET_weETH)
        );

        wrappedToken.grantRole(
            wrappedToken.DEFAULT_ADMIN_ROLE(),
            SEAMLESS_GOV_SHORT_TIMELOCK_ADDRESS
        );
        wrappedToken.grantRole(
            wrappedToken.DEFAULT_ADMIN_ROLE(), SEAMLESS_COMMUNITY_MULTISIG
        );

        wrappedToken.renounceRole(
            wrappedToken.DEFAULT_ADMIN_ROLE(), deployerAddress
        );

        vm.stopBroadcast();
    }
}
