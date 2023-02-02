import "@nomiclabs/hardhat-ethers";
import {account, CONTRACT_ABI, signAndSendTransaction, web3} from "./deploy";
import { keccak256, solidityKeccak256 } from 'ethers/lib/utils';
import { MerkleTree } from 'merkletreejs';

export async function setData(contract: any) {
  const gachaDataContract = new web3.eth.Contract(CONTRACT_ABI.DSP_GACHA_DATA.abi, contract.dspGachaData.address);
  console.log('Gacha Data 설정')
  let tx = await gachaDataContract.methods
    .setGachaInfos(
      getGachaData()
    );

  await signAndSendTransaction(contract.dspGachaData, tx);

  console.log("------------------------------------------------");
  const airdropUserContract = new web3.eth.Contract(CONTRACT_ABI.AIRDROP_USER.abi, contract.airdropUser.address);
  console.log('Airdrop User List 설정')
  const treeLeave = [getAirdropUserList(contract.gachaTicket)];
  // const hashFn = (data) => keccak256(data).slice(2);
  const tree = new MerkleTree(treeLeave, '', { sort: true });
  tx = await airdropUserContract.methods
    .setAirdropUserRoot([
      1, //tree round
      tree.getHexRoot()
    ]);
  await signAndSendTransaction(contract.airdropUser, tx);
  console.log("------------------------------------------------");

  console.log('Airdrop User Token limit 설정')
  tx = await airdropUserContract.methods
    .setAirdropMaxAmount([
      contract.gachaTicket.address,
      1500001,
      10
    ]);
  await signAndSendTransaction(contract.airdropUser, tx);
  console.log("------------------------------------------------");

  const airdropGachaTicketContract = new web3.eth.Contract(CONTRACT_ABI.AIRDROP_GACHA_TICKET.abi, contract.airdropGachaTicket.address);
  console.log('Airdrop Gacha Ticket Limit 설정')
  tx = await airdropGachaTicketContract.methods
    .setAirdropRemainCount(
      ...getAirdropGachaTicketLimit()
    );
  await signAndSendTransaction(contract.airdropGachaTicket, tx);
  console.log("------------------------------------------------");

  const dspCharacterDataContract = new web3.eth.Contract(CONTRACT_ABI.DSP_CHARACTER_DATA.abi, contract.dspCharacterData.address);
  console.log('영웅 정보  설정')
  tx = await dspCharacterDataContract.methods
    .setCharacterData(
      getCharacterData()
    );
  await signAndSendTransaction(contract.dspCharacterData, tx);
  console.log("------------------------------------------------");
}

function getGachaData() {
  return [
    [1500001, 'Hero Gacha NFT (Bronze)', [700,300,0,0,0], [[0,0,1000,0,0],[0,0,1000,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]], true]
  ]
}

function getCharacterData() {
  return [
    ['1',1,3,1,1,1,1,true],
    ['2',1,3,2,2,2,2,true],
    ['3',1,3,1,1,1,3,true],
    ['4',1,3,2,2,2,4,true],
    ['5',2,3,1,1,1,5,true],
    ['6',2,3,2,2,2,6,true],
    ['7',2,3,1,1,1,7,true],
    ['8',2,3,2,2,2,8,true],
  ]
}

export function getAirdropUserList(contract: any) {
  return solidityKeccak256(
    ['address', 'address', 'uint256', 'uint256'],
    [account.address, contract.address, 1500001, 10],
  );
}

function getAirdropGachaTicketLimit() {
  return [
    1500001,
    150000,
  ]
}