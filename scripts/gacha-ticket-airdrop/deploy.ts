import "@nomiclabs/hardhat-ethers";
import { contractDeploy } from "./contract-deploy";
import {setOperator} from "./set-operator";
import {setData} from "./set-data";
import {airdropGachaTicket} from "./airdrop-gacha-ticket";
const { createAlchemyWeb3 } = require("@alch/alchemy-web3");

export const web3 = createAlchemyWeb3('');
const PRIVATE_KEY = '';

export const account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);

export const OPERATOR = {
  GACHA_TICKET: 'DGT_SUPER_OPERATOR',
  AIRDROP_USER: 'AIRDROP_USER_SUPER_OPERATOR',
}

export const CONTRACT_ABI = {
  LUX_ON_ADMIN: require('../../artifacts/contracts/Admin/LuxOnAdmin.sol/LuxOnAdmin.json'),
  LUX_ON_SERVICE: require('../../artifacts/contracts/Admin/LuxOnService.sol/LuxOnService.json'),
  DSP_GACHA_DATA: require('../../artifacts/contracts/Admin/data/GachaData.sol/DspGachaData.json'),
  GACHA_TICKET: require('../../artifacts/contracts/LUXON/myPage/inventory/GachaTicket.sol/GachaTicket.json'),
  AIRDROP_USER: require('../../artifacts/contracts/Admin/data/AirdropUser.sol/AirdropUser.json'),
  AIRDROP_GACHA_TICKET: require('../../artifacts/contracts/Admin/AirdropGachaTicket.sol/AirdropGachaTicket.json')
}

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

async function deploy() {
  // 영입권 ERC1155 에어드랍 관련 contract deploy
  console.log('영입권 ERC1155 에어드랍 관련 contract deploy');
  console.log("------------------------------------------------");
  const contracts = await contractDeploy();

  // Operator 설정
  console.log('Operator 설정');
  console.log("------------------------------------------------");
  await setOperator(contracts);

  // 데이터 설정
  console.log('데이터 설정');
  console.log("------------------------------------------------");
  await setData(contracts);

  // 에어드랍 실행
  console.log('에어드랍 실행');
  console.log("------------------------------------------------");
  await airdropGachaTicket(contracts);

  console.log('finish');
}

deploy()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
