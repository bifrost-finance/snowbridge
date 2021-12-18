const BigNumber = require('bignumber.js');

const { expect } = require("chai")
    .use(require("chai-as-promised"))
    .use(require("chai-bignumber")(BigNumber))

const { TestTokenAddress, polkadotRecipientSS58, polkadotRecipient, bootstrap } = require('../src/fixtures');

const { ChannelId } = require("../src/helpers");

describe('Bridge', function () {

    let ethClient, subClient, subBalances;
    before(async function () {
        const clients = await bootstrap();
        ethClient = clients.ethClient;
        subClient = clients.subClient;
        this.erc20AssetId = subClient.api.createType('AssetId',
            { Token: TestTokenAddress }
        );

        subBalances = await subClient.subscribeAssetBalances(
            polkadotRecipientSS58, this.erc20AssetId, 2
        );


    });

    describe('test', function () {
        it('test balance', async function () {
            const amount = BigNumber('1000');
            const ethAccount = ethClient.accounts[1];
            console.log(`ethAccount is:${ethAccount}`)
            const beforeEthBalance = await ethClient.getErc20Balance(ethAccount);
            console.log(`ethBalance is:${beforeEthBalance}`)
            const beforeSubBalance = await subBalances[0];
            console.log(`subBalance is:${beforeSubBalance}`)
            const beefyBlock = await ethClient.getLatestBeefyBlock();
            console.log(`latests beefyBlock is:${beefyBlock}`)
        })
    })
})
