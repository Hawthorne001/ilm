// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IAccessControl } from
    "@openzeppelin/contracts/access/IAccessControl.sol";
import { ISwapper } from "../../../src/swap/Swapper.sol";
import { ILoopStrategy } from "../../../src/LoopStrategy.sol";
import { IWrappedTokenAdapter } from
    "../../../src/interfaces/IWrappedTokenAdapter.sol";
import { IAerodromeAdapter } from
    "../../../src/interfaces/IAerodromeAdapter.sol";
import { IUniversalAerodromeAdapter } from
    "../../../src/interfaces/IUniversalAerodromeAdapter.sol";
import { IWrappedERC20PermissionedDeposit } from
    "../../../src/tokens/WrappedERC20PermissionedDeposit.sol";
import { StrategyAssets } from "../../../src/types/DataTypes.sol";
import { ISwapAdapter } from "../../../src/interfaces/ISwapAdapter.sol";
import { DeployHelperLib } from "../DeployHelperLib.sol";
import { BaseMainnetConstants } from "../config/BaseMainnetConstants.sol";
import { IILMRegistry } from "../../../src/interfaces/IILMRegistry.sol";

interface IOwnable2Step {
    function transferOwnership(address newOwner) external;
    function acceptOwnership() external;
}

/// @notice Helper setup contract which guardian or governance can call through delegate call to setup this strategy
/// @dev Roles needed for this contract:
///         DEFAULT_ADMIN_ROLE on BASE_MAINNET_SEAMLESS_WRAPPED_cbBTC
///         DEFAULT_ADMIN_ROLE on SWAPPER
///         MANAGER_ROLE on SWAPPER
///         MANAGER_ROLE on WRAPPED_TOKEN_ADAPTER
///         MANAGER_ROLE on ILM_REGISTRY
///         MANAGER_ROLE on UNIVERSAL_AERODROME_ADAPTER
///  @dev all roles are renounced at the end of execution
contract DeployLoopStrategycbBTCoverUSDCGuardianPayload is
    BaseMainnetConstants
{
    error NotAuthorized();

    int24 public TICK_SPACING_USDC_cbBTC = 100;

    function run(ILoopStrategy strategy_1p5x, ILoopStrategy strategy_3x)
        external
    {
        if (
            msg.sender != SEAMLESS_COMMUNITY_MULTISIG
                && msg.sender != SEAMLESS_GOV_SHORT_TIMELOCK_ADDRESS
        ) {
            revert NotAuthorized();
        }

        StrategyAssets memory strategyAssets = strategy_1p5x.getAssets();

        IWrappedERC20PermissionedDeposit wrappedToken =
            IWrappedERC20PermissionedDeposit(address(strategyAssets.collateral));
        IWrappedTokenAdapter wrappedTokenAdapter =
            IWrappedTokenAdapter(WRAPPED_TOKEN_ADAPTER);

        IAccessControl(address(wrappedToken)).grantRole(
            wrappedToken.DEPOSITOR_ROLE(), address(strategy_1p5x)
        );
        IAccessControl(address(wrappedToken)).grantRole(
            wrappedToken.DEPOSITOR_ROLE(), address(strategy_3x)
        );
        IAccessControl(address(wrappedToken)).grantRole(
            wrappedToken.DEPOSITOR_ROLE(), WRAPPED_TOKEN_ADAPTER
        );

        wrappedTokenAdapter.setWrapper(
            wrappedToken.underlying(),
            IERC20(address(wrappedToken)),
            wrappedToken
        );

        DeployHelperLib._constructAndSetPaths(
            IUniversalAerodromeAdapter(UNIVERSAL_AERODROME_ADAPTER),
            BASE_MAINNET_USDC,
            BASE_MAINNET_cbBTC,
            TICK_SPACING_USDC_cbBTC
        );

        DeployHelperLib._setSwapperRouteBetweenWrappedAndToken(
            ISwapper(SWAPPER),
            wrappedToken,
            strategyAssets.debt,
            ISwapAdapter(address(wrappedTokenAdapter)),
            ISwapAdapter(UNIVERSAL_AERODROME_ADAPTER),
            50000 // 0.05 % - value is set to 50000 / 100000000 which is pool fee at time of deployment
        );

        IILMRegistry(ILM_REGISTRY).addILM(address(strategy_1p5x));
        IILMRegistry(ILM_REGISTRY).addILM(address(strategy_3x));

        bytes32 STRATEGY_ROLE = keccak256("STRATEGY_ROLE");
        IAccessControl(SWAPPER).grantRole(STRATEGY_ROLE, address(strategy_1p5x));
        IAccessControl(SWAPPER).grantRole(STRATEGY_ROLE, address(strategy_3x));

        _renounceDefaultAdmin(address(wrappedToken));
        _renounceDefaultAdmin(SWAPPER);
        _renounceManager(address(wrappedTokenAdapter));
        _renounceManager(SWAPPER);
        _renounceManager(ILM_REGISTRY);
        _renounceManager(UNIVERSAL_AERODROME_ADAPTER);
    }

    function _renounceDefaultAdmin(address contractAddress) internal {
        bytes32 DEFAULT_ADMIN_ROLE = 0x00;
        IAccessControl(contractAddress).renounceRole(
            DEFAULT_ADMIN_ROLE, address(this)
        );
    }

    function _renounceManager(address contractAddress) internal {
        bytes32 MANAGER_ROLE = keccak256("MANAGER_ROLE");
        IAccessControl(contractAddress).renounceRole(
            MANAGER_ROLE, address(this)
        );
    }
}
