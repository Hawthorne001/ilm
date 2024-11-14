const { ethers } = require('ethers');
const { expect } = require('chai');
const sinon = require('sinon');
const {
    isStrategyOverexposed,
    isStrategyAtRisk,
    isOracleOut,
    checkAlertChannelsExist,
    hasEPSDecreased,
} = require('../src/actions/checks');
const { equityPerShare } = require('../src/actions/utils');

describe('checks', () => {
    let strategyStub;
    let oracleStub;
    let storeStub;

    beforeEach(() => {
        strategyStub = {
            address: '0xStrategy',
            currentCollateralRatio: sinon.stub(),
            getCollateralRatioTargets: sinon.stub(),
            debtUSD: sinon.stub(),
            collateralUSD: sinon.stub(),
            equity: sinon.stub(),
            totalSupply: sinon.stub(),
        };

        oracleStub = {
            address: '0xOracle',
            latestRoundData: sinon.stub(),
        };

        storeStub = {
            put: sinon.stub(),
            get: sinon.stub(),
        };
    });

    afterEach(() => {
        sinon.restore();
    });

    describe('isStrategyAtRisk', () => {
        const healthFactorThreshold = 10 ** 8;

        it('returns false and healthFactor value when healthFactor is above healthFactorThreshold', async () => {
            strategyStub.debtUSD.resolves(10 ** 8);
            strategyStub.collateralUSD.resolves(healthFactorThreshold + 1);

            const result = await isStrategyAtRisk(strategyStub, healthFactorThreshold);

            expect(result.isAtRisk).to.eq(false);
            expect(result.healthFactor).to.deep.eq(
                ethers.BigNumber.from(healthFactorThreshold + 1)
            );
        });

        it('returns true and healthFactor value when healthFactor is below healthFactorThreshold', async () => {
            strategyStub.debtUSD.resolves(10 ** 8);
            strategyStub.collateralUSD.resolves(healthFactorThreshold - 1);

            const result = await isStrategyAtRisk(strategyStub, healthFactorThreshold);

            expect(result.isAtRisk).to.eq(true);
            expect(result.healthFactor).to.deep.eq(
                ethers.BigNumber.from(healthFactorThreshold - 1)
            );
        });

        it('should handle errors', async () => {
            const consoleErrorStub = sinon.stub(console, 'error');
            const error = new Error('Test error');

            strategyStub.debtUSD.rejects(error);

            try {
                await isStrategyAtRisk(strategyStub, healthFactorThreshold);
            } catch (err) {
                expect(err).to.equal(error);
            }

            const actualCall = consoleErrorStub.getCall(0);
            const expectedMessage = 'An error has occurred during health factor check: ';

            expect(actualCall.args[0]).to.include(expectedMessage);
            expect(actualCall.args[1]).to.equal(error);

            consoleErrorStub.restore();
        });
    });

    describe('isStrategyOverexposed', () => {
        it('returns false, and, currentCollateralRatio and minForRebalance values when currentCollateralRatio value is above minForRebalance value', async () => {
            strategyStub.currentCollateralRatio.resolves(100);
            strategyStub.getCollateralRatioTargets.resolves([100, 90, 110, 99, 101]);

            const result = await isStrategyOverexposed(strategyStub);

            expect(result.isOverExposed).to.eq(false);
            expect(result.current).to.deep.eq(ethers.BigNumber.from(String(100).toString()));
            expect(result.min).to.deep.eq(ethers.BigNumber.from(String(90).toString()));
        });

        it('returns true, and, currentCollateralRatio and minForRebalance values when currentCollateralRatio value is beneath minForRebalance value', async () => {
            strategyStub.currentCollateralRatio.resolves(85);
            strategyStub.getCollateralRatioTargets.resolves([100, 90, 110, 99, 101]);

            const result = await isStrategyOverexposed(strategyStub);

            expect(result.isOverExposed).to.eq(true);
            expect(result.current).to.deep.eq(ethers.BigNumber.from(String(85).toString()));
            expect(result.min).to.deep.eq(ethers.BigNumber.from(String(90).toString()));
        });

        it('logs an error and throw it when isStrategyOverexposed call fails', async function () {
            const consoleErrorStub = sinon.stub(console, 'error');
            const error = new Error('Test error');
            strategyStub.currentCollateralRatio.resolves(ethers.BigNumber.from('1000'));
            strategyStub.getCollateralRatioTargets.rejects(error);

            try {
                await isStrategyOverexposed(strategyStub);
            } catch (err) {
                expect(err).to.equal(error);
            }

            const actualCall = consoleErrorStub.getCall(0);
            const expectedMessage = 'An error has occurred during collateral ratio check: ';

            expect(actualCall.args[0]).to.include(expectedMessage);
            expect(actualCall.args[1]).to.equal(error);

            consoleErrorStub.restore();
        });
    });

    describe('isOracleOut', () => {
        it('calls store.put with the latest update', async function () {
            const lastUpdate = '1620000000';
            const latestUpdateBN = ethers.BigNumber.from(Math.floor(Date.now() / 1000));
            const latestUpdate = latestUpdateBN.toString();

            storeStub.get.withArgs(oracleStub.address).resolves(lastUpdate);
            oracleStub.latestRoundData.resolves([null, null, null, latestUpdateBN]);

            await isOracleOut(storeStub, oracleStub);

            expect(storeStub.put.calledOnce).to.be.true;
            expect(storeStub.put.calledWith(oracleStub.address, latestUpdate)).to.be.true;
        });

        it('return secondSinceLastUpdate, isOut and oracleAddress values when lastUpdate is neither null nor undefined', async () => {
            const lastUpdate = '1620000000';
            const latestUpdateBN = ethers.BigNumber.from(Math.floor(Date.now() / 1000));

            const secondsSinceLastUpdate = parseInt(lastUpdate) - Math.floor(Date.now() / 1000);

            storeStub.get.withArgs(oracleStub.address).resolves(lastUpdate);
            oracleStub.latestRoundData.resolves([null, null, null, latestUpdateBN]);

            const result = await isOracleOut(storeStub, oracleStub);

            expect(result.isOut).to.be.false;
            expect(result.secondSinceLastUpdate).to.eq(secondsSinceLastUpdate);
            expect(result.oracleAddress).to.eq(oracleStub.address);
        });
    });

    describe('hasEPSDecreased', () => {
        it('updates EPS in store', async () => {
            const equityBN = ethers.BigNumber.from('1001');
            const totalSupplyBN = ethers.BigNumber.from('1');
            storeStub.get.withArgs(strategyStub.address).resolves('1000');
            strategyStub.equity.resolves(equityBN);
            strategyStub.totalSupply.resolves(totalSupplyBN);

            await hasEPSDecreased(storeStub, strategyStub);

            expect(storeStub.put.calledOnce).to.be.true;
            expect(
                storeStub.put.calledWith(
                    strategyStub.address,
                    equityBN.div(totalSupplyBN).mul(ethers.utils.parseUnits('1.0', 18)).toString()
                )
            ).to.be.true;
        });
        it('returns previous EPS, current EPS, strategy address and hasEPSDecreased values', async () => {
            const equityBN = ethers.BigNumber.from('1001');
            const totalSupplyBN = ethers.BigNumber.from('1');
            storeStub.get.withArgs(strategyStub.address).resolves('1000');
            strategyStub.equity.resolves(equityBN);
            strategyStub.totalSupply.resolves(totalSupplyBN);

            const result = await hasEPSDecreased(storeStub, strategyStub);

            expect(result.strategyAddress).to.eq(strategyStub.address);
            expect(result.hasEPSDecreased).to.be.false;
            expect(result.prevEPS).to.eq('1000');
            expect(result.currentEPS).to.deep.eq(
                equityBN.div(totalSupplyBN).mul(ethers.utils.parseUnits('1.0', 18))
            );
        });
        it('logs and error and throws it when hasEPSDecreased call fails', async () => {
            const consoleErrorStub = sinon.stub(console, 'error');
            const error = new Error('Test error');
            storeStub.get.withArgs(strategyStub.address).resolves('1000');
            strategyStub.equity.resolves(ethers.BigNumber.from('1000'));
            strategyStub.totalSupply.rejects(error);

            try {
                await hasEPSDecreased(storeStub, strategyStub);
            } catch (err) {
                expect(err).to.equal(error);
            }

            const actualCall = consoleErrorStub.getCall(0);
            const expectedMessage = 'An error has occured during equityPerShare calculation: ';

            expect(actualCall.args[0]).to.include(expectedMessage);
            expect(actualCall.args[1]).to.equal(error);

            consoleErrorStub.restore();
        });
    });

    describe('checkAlertChannelsExist', () => {
        let clientStub;

        beforeEach(() => {
            clientStub = {
                monitor: {
                    listNotificationChannels: sinon.stub(),
                },
            };
        });

        it('handles errors when array returned is empty', async () => {
            clientStub.monitor.listNotificationChannels.resolves([]);

            const consoleErrorStub = sinon.stub(console, 'error');

            await checkAlertChannelsExist(clientStub);

            sinon.assert.calledOnce(consoleErrorStub);
            sinon.assert.calledWith(consoleErrorStub, 'No alert notification channels exist.');

            console.error.restore();
        });

        it('handles errors when array returned is non-empty but no names resolve to `seamless-alerts`', async () => {
            clientStub.monitor.listNotificationChannels.resolves([
                {
                    name: 'not-seamless-alerts',
                },
            ]);

            const consoleErrorStub = sinon.stub(console, 'error');

            await checkAlertChannelsExist(clientStub);

            sinon.assert.calledOnce(consoleErrorStub);
            sinon.assert.calledWith(consoleErrorStub, 'No alert notification channels exist.');

            console.error.restore();
        });

        it('throws no error when array returns is non-empty and has an item with the name property equal to `seamless-alerts`', async () => {
            clientStub.monitor.listNotificationChannels.resolves([
                {
                    name: 'seamless-alerts',
                },
            ]);

            const consoleErrorStub = sinon.stub(console, 'error');

            await checkAlertChannelsExist(clientStub);

            sinon.assert.notCalled(consoleErrorStub);

            console.error.restore();
        });
    });
});
