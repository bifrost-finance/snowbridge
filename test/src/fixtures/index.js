const fs = require('fs');

const contracts = JSON.parse(fs.readFileSync('/tmp/snowbridge/contracts.json', 'utf8'));

const TestToken = contracts.contracts.TestToken;
const TestToken721 = contracts.contracts.TestToken721;
const BeefyLightClient = contracts.contracts.BeefyLightClient;
const EthClient = require('../../src/ethclient').EthClient;
const SubClient = require('../../src/subclient').SubClient;

const polkadotRecipient = "0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d";
const polkadotRecipientSS58 = "gXCcrjjFX3RPyhHYgwZDmw8oe4JFpd5anko3nTY8VrmnJpe";
const polkadotSenderSS58 = polkadotRecipientSS58;
const treasuryAddressSS58 = "eCSrvbDSm6Frn32BexjruLAhoZuuRnZUYSz14V5q2xnFEyC";
const ethEndpoint = 'ws://localhost:8546';
const parachainEndpoint = 'ws://localhost:11144';
const testNetworkID = '15';

const TestTokenAddress = TestToken.address;
const TestToken721Address = TestToken721.address;
const BeefyLightClientAddress = BeefyLightClient.address;

const ETH_TO_PARA_WAIT_TIME = 60000;
const PARA_TO_ETH_WAIT_TIME = 100000;

async function bootstrap() {
  const ethClient = new EthClient(ethEndpoint, testNetworkID);
  const subClient = new SubClient(parachainEndpoint);
  await subClient.connect();
  await ethClient.initialize();
  return { ethClient, subClient };
}

module.exports = {
  bootstrap, polkadotRecipient,
  polkadotRecipientSS58, polkadotSenderSS58, treasuryAddressSS58,
  TestTokenAddress, TestToken721Address,
  ETH_TO_PARA_WAIT_TIME, PARA_TO_ETH_WAIT_TIME
};
