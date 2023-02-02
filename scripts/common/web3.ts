import { URI } from './enums';
const { createAlchemyWeb3 } = require("@alch/alchemy-web3");
const web3 = createAlchemyWeb3(URI.ALCHEMY);
const PRIVATE_KEY = '';
export const account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);

export async function signAndSendTransaction(contract: any, tx: any) {
    await web3.eth.sendSignedTransaction(
      (await web3.eth.accounts.signTransaction(
        {
          to: contract.address,
          data: tx.encodeABI(),
          gas: await tx.estimateGas({ from: account.address }),
          gasPrice: await web3.eth.getGasPrice(),
          gasLimit: 3000000,
          nonce: await web3.eth.getTransactionCount(account.address),
          chainId: await web3.eth.getChainId(),
        },
        PRIVATE_KEY,
      )).rawTransaction
    );
}

export const Web3Alchemy = web3.eth;