# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

.PHONY: test clean

# Build & test
build                   :; forge build
coverage                :; forge coverage
gas                     :; forge test --gas-report
gas-check               :; forge snapshot --check --tolerance 1
snapshot                :; forge snapshot
clean                   :; forge clean
fmt                     :; forge fmt
run-simulation          :; mkdir -p ./test/integration/output && forge test --mt test_e2eSimulation
test-invariant-rewards  :; forge test --mt invariant_LoopStrategyRewards
test        						:; forge test --no-match-test "test_e2eSimulation|invariant" --gas-report $(VERBOSITY)
test-verbose       			:; make test VERBOSITY="-vvv"

# Deploy
deploy-wrappedwstETH-base-mainnet 								:; forge script script/deploy/base-mainnet/DeployWrappedwstETH.s.sol --tc DeployWrappedwstETH --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvvv
deploy-wrappedwstETH-tenderly 										:; forge script script/deploy/base-mainnet/DeployWrappedwstETH.s.sol --tc DeployWrappedwstETH --force --rpc-url tenderly --slow --broadcast -vvvv --verify --verifier-url ${TENDERLY_FORK_VERIFIER_URL} --etherscan-api-key ${TENDERLY_ACCESS_KEY}

deploy-loopStrategyWstETHoverETH-base-mainnet 		:; forge script script/deploy/base-mainnet/DeployLoopStrategyWstETHoverETH.s.sol --tc DeployLoopStrategyWstETHoverETH --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvvv
deploy-loopStrategyWstETHoverETH-tenderly 				:; forge script script/deploy/base-mainnet/DeployLoopStrategyWstETHoverETH.s.sol --tc DeployLoopStrategyWstETHoverETH --force --rpc-url tenderly --slow --broadcast -vvvv --verify --verifier-url ${TENDERLY_FORK_VERIFIER_URL} --etherscan-api-key ${TENDERLY_ACCESS_KEY}

deploy-loopStrategyImplementation-base-mainnet		:; forge script script/deploy/DeployLoopStrategyImplementation.s.sol --tc DeployLoopStrategyImplementation --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvvv
deploy-loopStrategyImplementation-tenderly		    :; forge script script/deploy/DeployLoopStrategyImplementation.s.sol --tc DeployLoopStrategyImplementation --force --rpc-url tenderly --slow --broadcast -vvvv --verify --verifier-url ${TENDERLY_FORK_VERIFIER_URL} --etherscan-api-key ${TENDERLY_ACCESS_KEY}

deploy-swapperImplementation-base-mainnet					:; forge script script/deploy/DeploySwapperImplementation.s.sol --tc DeploySwapperImplementation --force --rpc-url base  --chain base --slow --broadcast --verify --delay 5 -vvvv
deploy-swapperImplementation-tenderly		    			:; forge script script/deploy/DeploySwapperImplementation.s.sol --tc DeploySwapperImplementation --force --rpc-url tenderly --slow --broadcast -vvvv --verify --verifier-url ${TENDERLY_FORK_VERIFIER_URL} --etherscan-api-key ${TENDERLY_ACCESS_KEY}

deploy-wrappedWETH-base-mainnet 									:; forge script script/deploy/base-mainnet/DeployWrappedWETH.s.sol --tc DeployWrappedWETH --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvvv
deploy-wrappedWETH-tenderly 											:; forge script script/deploy/base-mainnet/DeployWrappedWETH.s.sol --tc DeployWrappedWETH --force --rpc-url tenderly --slow --broadcast -vvvv --verify --verifier-url ${TENDERLY_FORK_VERIFIER_URL} --etherscan-api-key ${TENDERLY_ACCESS_KEY}

deploy-loopStrategyETHoverUSDC-base-mainnet 			:; forge script script/deploy/base-mainnet/DeployLoopStrategyETHoverUSDC.s.sol --tc DeployLoopStrategyETHoverUSDC --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvvv
deploy-loopStrategyETHoverUSDC-tenderly 					:; forge script script/deploy/base-mainnet/DeployLoopStrategyETHoverUSDC.s.sol --tc DeployLoopStrategyETHoverUSDC --force --rpc-url tenderly --slow --broadcast -vvvv --verify --verifier-url ${TENDERLY_FORK_VERIFIER_URL} --etherscan-api-key ${TENDERLY_ACCESS_KEY}

deploy-ilmregistry-base-mainnet										:; forge script script/deploy/base-mainnet/DeployILMRegistry.s.sol --tc DeployILMRegistry --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvvv
deploy-ilmregistry-fork		        								:; forge script script/deploy/base-mainnet/DeployILMRegistry.s.sol --tc DeployILMRegistry --force --rpc-url tenderly --slow --broadcast -vvvv --verify --verifier-url ${TENDERLY_FORK_VERIFIER_URL} --etherscan-api-key ${TENDERLY_ACCESS_KEY}

deploy-loopStrategyETHoverUSDC-3x-base-mainnet 			:; forge script script/deploy/base-mainnet/DeployLoopStrategyETHoverUSDC_3x.s.sol --tc DeployLoopStrategyETHoverUSDC_3x --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvvv
deploy-loopStrategyETHoverUSDC-3x-tenderly 					:; forge script script/deploy/base-mainnet/DeployLoopStrategyETHoverUSDC_3x.s.sol --tc DeployLoopStrategyETHoverUSDC_3x --force --rpc-url tenderly --slow --broadcast -vvvv --verify --verifier-url ${TENDERLY_FORK_VERIFIER_URL} --etherscan-api-key ${TENDERLY_ACCESS_KEY}

deploy-wrappedTokenAdapter-base-mainnet :; 	 forge script script/deploy/base-mainnet/DeployWrappedTokenAdapter.s.sol --tc DeployWrappedTokenAdapter --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvvv
deploy-wrappedTokenAdapter-tenderly 		:;   forge script script/deploy/base-mainnet/DeployWrappedTokenAdapter.s.sol --tc DeployWrappedTokenAdapter --force --rpc-url tenderly --slow --broadcast -vvvv --verify --verifier-url ${TENDERLY_FORK_VERIFIER_URL} --etherscan-api-key ${TENDERLY_ACCESS_KEY}

deploy-universalAerodromeAdapter-base-mainnet 	:; forge script script/deploy/base-mainnet/DeployUniversalAerodromeAdapter.s.sol --tc DeployUniversalAerodromeAdapter --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvvv
deploy-universalAerodromeAdapter-tenderly 			:; forge script script/deploy/base-mainnet/DeployUniversalAerodromeAdapter.s.sol --tc DeployUniversalAerodromeAdapter --force --rpc-url tenderly --slow --broadcast -vvvv --verify --verifier-url ${TENDERLY_FORK_VERIFIER_URL} --etherscan-api-key ${TENDERLY_ACCESS_KEY}