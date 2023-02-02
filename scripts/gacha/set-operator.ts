import "@nomiclabs/hardhat-ethers";
import {account, CONTRACT_ABI, OPERATOR, signAndSendTransaction, web3} from "./deploy";

export async function setOperator(contract: any) {
  const luxOnAdminContract = new web3.eth.Contract(CONTRACT_ABI.LUX_ON_ADMIN.abi, contract.luxOnAdmin.address);

  console.log('AirdropGachaTicket & gacha machine -> GachaTicket Operator 설정')
  let tx = await luxOnAdminContract.methods
    .setSuperOperator(
      OPERATOR.GACHA_TICKET,
      [contract.airdropGachaTicket.address, contract.gachaMachineByGachaTicket.address],
      true
    );

  await signAndSendTransaction(contract.luxOnAdmin, tx);
  console.log("------------------------------------------------");
  console.log('AirdropGachaTicket -> AirdropUser Operator 설정')
  tx = await luxOnAdminContract.methods
    .setSuperOperator(
      OPERATOR.AIRDROP_USER,
      [contract.airdropGachaTicket.address, account.address],
      true
    );

  await signAndSendTransaction(contract.luxOnAdmin, tx);
  console.log("------------------------------------------------");

  console.log('gacha machine -> lct 설정')
  tx = await luxOnAdminContract.methods
    .setSuperOperator(
      OPERATOR.LCT,
      [contract.gachaMachineByGachaTicket.address, contract.erc721Centralization.address, contract.gachaMachine.address],
      true
    );

  await signAndSendTransaction(contract.luxOnAdmin, tx);
  console.log("------------------------------------------------");

  console.log('gacha machine -> erc 721 centralization 설정')
  tx = await luxOnAdminContract.methods
    .setSuperOperator(
      OPERATOR.ERC721_CENTRALIZATION,
      [contract.gachaMachineByGachaTicket.address],
      true
    );

  await signAndSendTransaction(contract.luxOnAdmin, tx);
  console.log("------------------------------------------------");
}