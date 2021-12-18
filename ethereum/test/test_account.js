const ethers = require('ethers');
let mnemonic = "stone speak what ritual switch pigeon weird dutch burst shaft nature shove";
let mnemonicWallet = ethers.Wallet.fromMnemonic(mnemonic);
console.log(mnemonicWallet.privateKey);

var Wallet = require('ethereumjs-wallet');
var EthUtil = require('ethereumjs-util');

// Get a wallet instance from a private key
const privateKeyBuffer = EthUtil.toBuffer('0x8013383de6e5a891e7754ae1ef5a21e7661f1fe67cd47ca8ebf4acd6de66879a');
const wallet = Wallet['default'].fromPrivateKey(privateKeyBuffer);

// Get a public key
const publicKey = wallet.getPublicKeyString();
console.log(publicKey);
const address = wallet.getAddressString();
console.log(address);
