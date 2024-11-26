// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.21;

import { Script } from "forge-std/Script.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IAccessControl } from
    "@openzeppelin/contracts/access/IAccessControl.sol";
import { ISwapper } from "../../../src/swap/Swapper.sol";
import { IRouter } from "../../../src/vendor/aerodrome/IRouter.sol";
import { LoopStrategy, ILoopStrategy } from "../../../src/LoopStrategy.sol";
import { IWrappedTokenAdapter } from
    "../../../src/interfaces/IWrappedTokenAdapter.sol";
import { IAerodromeAdapter } from
    "../../../src/interfaces/IAerodromeAdapter.sol";
import { DeployHelper } from "../DeployHelper.s.sol";
import {
    WrappedERC20PermissionedDeposit,
    IWrappedERC20PermissionedDeposit
} from "../../../src/tokens/WrappedERC20PermissionedDeposit.sol";
import {
    LoopStrategyConfig,
    ERC20Config,
    ReserveConfig,
    CollateralRatioConfig,
    SwapperConfig,
    LoopStrategyConfigCore
} from "../config/LoopStrategyConfig.sol";
import {
    CollateralRatio, StrategyAssets
} from "../../../src/types/DataTypes.sol";
import { USDWadRayMath } from "../../../src/libraries/math/USDWadRayMath.sol";
import { BaseMainnetConstants } from "../config/BaseMainnetConstants.sol";
import { ISwapAdapter } from "../../../src/interfaces/ISwapAdapter.sol";
import { DeployHelperLib } from "../DeployHelperLib.sol";
import { DeployLoopStrategycbBTCoverUSDCGuardianPayload } from
    "./DeployLoopStrategycbBTCoverUSDCGuardianPayload.sol";

contract DeployLoopStrategycbBTCoverUSDC_1p5x_Config is BaseMainnetConstants {
    uint256 public constant cbBTC_UNIT = 1e8;
    uint256 public constant USD_UNIT = 1e8;

    uint256 public assetsCap = 5 * cbBTC_UNIT;

    uint256 public maxSlippageOnRebalance = 1_000000; // 1%

    // 1.5x leverage (and 1.5x price exposure)
    uint256 leverage = USDWadRayMath.usdDiv(150, 100);
    uint256 targetCollateralRatio =
        USDWadRayMath.usdDiv(leverage, leverage - USD_UNIT);

    // targets for rebalance are +- 10%
    uint256 rebalanceOffset = USDWadRayMath.usdDiv(10, 100);

    LoopStrategyConfigCore public cbBTCoverUSDC_1p5x = LoopStrategyConfigCore({
        strategyAssets: StrategyAssets({
            underlying: IERC20(BASE_MAINNET_cbBTC),
            collateral: IERC20(BASE_MAINNET_SEAMLESS_WRAPPED_cbBTC),
            debt: IERC20(BASE_MAINNET_USDC)
        }),
        strategyERC20Config: ERC20Config({
            name: "Seamless ILM 1.5x Loop cbBTC/USDC",
            symbol: "ilm-cbBTC/USDC-1.5xloop"
        }),
        collateralRatioConfig: CollateralRatioConfig({
            collateralRatioTargets: CollateralRatio({
                target: targetCollateralRatio,
                minForRebalance: USDWadRayMath.usdMul(
                    targetCollateralRatio, USD_UNIT - rebalanceOffset
                ),
                maxForRebalance: USDWadRayMath.usdMul(
                    targetCollateralRatio, USD_UNIT + rebalanceOffset
                ),
                maxForDepositRebalance: targetCollateralRatio,
                minForWithdrawRebalance: targetCollateralRatio
            }),
            ratioMargin: 1, // 0.000001% ratio margin
            maxIterations: 20
        })
    });
}

contract DeployLoopStrategycbBTCoverUSDC_1p5x is
    Script,
    DeployHelper,
    DeployLoopStrategycbBTCoverUSDC_1p5x_Config
{
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PK");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        LoopStrategy strategy = _deployLoopStrategyCore(
            deployerAddress, ISwapper(SWAPPER), cbBTCoverUSDC_1p5x
        );

        // needed for setting assetsCap and maxSlippageOnRebalance
        strategy.grantRole(strategy.MANAGER_ROLE(), deployerAddress);

        strategy.setAssetsCap(assetsCap);
        strategy.setMaxSlippageOnRebalance(maxSlippageOnRebalance);

        // set roles on strategy
        _grantRoles(strategy, strategy.DEFAULT_ADMIN_ROLE());
        _grantRoles(strategy, strategy.MANAGER_ROLE());
        _grantRoles(strategy, strategy.UPGRADER_ROLE());
        _grantRoles(strategy, strategy.PAUSER_ROLE());

        // renounce deployer roles on strategy
        strategy.renounceRole(strategy.MANAGER_ROLE(), deployerAddress);
        strategy.renounceRole(strategy.DEFAULT_ADMIN_ROLE(), deployerAddress);

        address guardianPayload =
            address(new DeployLoopStrategycbBTCoverUSDCGuardianPayload());
        _logAddress("GuardianPayloadContract", guardianPayload);

        vm.stopBroadcast();
    }

    function _grantRoles(IAccessControl accessContract, bytes32 role)
        internal
    {
        accessContract.grantRole(role, SEAMLESS_GOV_SHORT_TIMELOCK_ADDRESS);
        accessContract.grantRole(role, SEAMLESS_COMMUNITY_MULTISIG);
    }
}
