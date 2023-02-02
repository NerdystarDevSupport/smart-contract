import "@nomiclabs/hardhat-ethers";
import {account, CONTRACT_ABI, signAndSendTransaction, web3} from "./deploy";
import {getAirdropUserList} from "./set-data";
import {MerkleTree} from "merkletreejs";

export async function gacha(contract: any) {
  const airdropGachaTicket = new web3.eth.Contract(CONTRACT_ABI.AIRDROP_GACHA_TICKET.abi, contract.airdropGachaTicket.address);

  console.log('Airdrop Gacha Ticket')
  let tx = await airdropGachaTicket.methods
    .airdropMany(getAirdropList(contract.gachaTicket));

  await signAndSendTransaction(contract.airdropGachaTicket, tx);
  console.log("------------------------------------------------");

  const gachaMachineByGachaTicket = new web3.eth.Contract(CONTRACT_ABI.GACHA_MACHINE_BY_GACHA_TICKET.abi, contract.gachaMachineByGachaTicket.address);

  console.log('Gacha Machine By Gacha Ticket')
  tx = await gachaMachineByGachaTicket.methods
    .gacha([
      1500001,
      1,
      false // is centralization
    ]);

  await signAndSendTransaction(contract.gachaMachineByGachaTicket, tx);
  console.log("------------------------------------------------");

  const gachaMachine = new web3.eth.Contract(CONTRACT_ABI.GACHA_MACHINE.abi, contract.gachaMachine.address);

  console.log('Gacha')
  tx = await gachaMachine.methods
    .gachaActor([
      [1500001,[
        [
          account.address,
          1, // token id
          "0xd2077852e56644b6a73855bdb715a307c14ec185f363caba5dd8ed6e33ba5cb7" // 중앙 서버에서 주입하는 랜덤 seed
        ]
      ]]
    ]);

  await signAndSendTransaction(contract.gachaMachine, tx);
  console.log("------------------------------------------------");
}

function getAirdropList(contract: any) {
  const treeLeave = [getAirdropUserList(contract)];
  // const hashFn = (data) => keccak256(data).slice(2);
  const tree = new MerkleTree(treeLeave, '', { sort: true });
  return [[account.address, 1500001, 10, 1, tree.getHexProof(getAirdropUserList(contract))]];
}