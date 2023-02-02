import "@nomiclabs/hardhat-ethers";
import { CONTRACT_ABI, signAndSendTransaction, web3} from "./deploy";
import {getAirdropUserList} from "./set-data";
import {MerkleTree} from "merkletreejs";

export async function airdropGachaTicket(contract: any) {
  const airdropGachaTicket = new web3.eth.Contract(CONTRACT_ABI.AIRDROP_GACHA_TICKET.abi, contract.airdropGachaTicket.address);

  console.log('Airdrop Gacha Ticket')
  let tx = await airdropGachaTicket.methods
    .airdropMany(getAirdropList(contract.gachaTicket));

  await signAndSendTransaction(contract.airdropGachaTicket, tx);
  console.log("------------------------------------------------");
}

function getAirdropList(contract: any) {
  const treeLeave = [getAirdropUserList(contract)];
  // const hashFn = (data) => keccak256(data).slice(2);
  const tree = new MerkleTree(treeLeave, '', { sort: true });
  return [['0x382E1bAe913EDa109F6Cfae87d4e29Dd449Fc424', 1500001, 10, 1, tree.getHexProof(
    getAirdropUserList(contract),
  )]];
}