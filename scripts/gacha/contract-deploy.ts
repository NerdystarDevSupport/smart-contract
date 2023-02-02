import "@nomiclabs/hardhat-ethers";
import { ethers } from "hardhat";
import { OPERATOR } from "./deploy";

export async function contractDeploy() {
  // Start deployment, returning a promise that resolves to a contract object
  console.log("1. LuxOnAdmin deploy start");
  const luxOnAdmin = await (await ethers.getContractFactory("LuxOnAdmin")).deploy();
  await luxOnAdmin.deployed();
  console.log("LuxOnAdmin Contract address:", luxOnAdmin.address);
  console.log("------------------------------------------------");

  console.log("2. LuxOnService deploy start");
  const luxOnService = await (await ethers.getContractFactory("LuxOnService")).deploy();
  await luxOnService.deployed();
  console.log("LuxOnService Contract address:", luxOnService.address);
  console.log("------------------------------------------------");

  console.log("3. GachaData deploy start");
  const dspGachaData = await (await ethers.getContractFactory("DspGachaData")).deploy();
  await dspGachaData.deployed();
  console.log("GachaData Contract address:", dspGachaData.address);
  console.log("------------------------------------------------");

  console.log("4. GachaTicket deploy start");
  const gachaTicket = await (await ethers.getContractFactory("GachaTicket")).deploy(OPERATOR.GACHA_TICKET, luxOnAdmin.address);
  await gachaTicket.deployed();
  console.log("GachaData Contract address:", gachaTicket.address);
  console.log("------------------------------------------------");

  console.log("5. AirdropUser deploy start");
  const airdropUser =
    await (await ethers.getContractFactory("AirdropUser"))
      .deploy(
        OPERATOR.AIRDROP_USER,
        luxOnAdmin.address
      );
  await airdropUser.deployed();
  console.log("AirdropUser Contract address:", airdropUser.address);
  console.log("------------------------------------------------");

  console.log("6. AirdropGachaTicket deploy start");
  const airdropGachaTicket =
    await (await ethers.getContractFactory("AirdropGachaTicket"))
      .deploy(
        gachaTicket.address,
        dspGachaData.address,
        airdropUser.address,
        luxOnService.address
      );
  await airdropGachaTicket.deployed();
  console.log("AirdropGachaTicket Contract address:", airdropGachaTicket.address);
  console.log("------------------------------------------------");

  console.log("7. Dsp Character Data deploy start");
  const dspCharacterData =
    await (await ethers.getContractFactory("DspCharacterData"))
      .deploy();
  await dspCharacterData.deployed();
  console.log("DspCharacterData Contract address:", dspCharacterData.address);
  console.log("------------------------------------------------");

  console.log("8. lct deploy start");
  const lct =
    await (await ethers.getContractFactory("LCT"))
      .deploy(
        OPERATOR.LCT,
        luxOnAdmin.address
      );
  await lct.deployed();
  console.log("lct Contract address:", lct.address);
  console.log("------------------------------------------------");

  console.log("9. erc721 centralization deploy start");
  const erc721Centralization =
    await (await ethers.getContractFactory("ERC721Centralization"))
      .deploy(
        OPERATOR.ERC721_CENTRALIZATION,
        luxOnAdmin.address
      );
  await erc721Centralization.deployed();
  console.log("Erc721Centralization Contract address:", erc721Centralization.address);
  console.log("------------------------------------------------");

  console.log("10. gachaMachineByGachaTicket deploy start");
  const gachaMachineByGachaTicket =
    await (await ethers.getContractFactory("GachaMachineByGachaTicket"))
      .deploy(
        lct.address,
        [gachaTicket.address, [1500001]],
        erc721Centralization.address,
        dspCharacterData.address,
        dspGachaData.address,
        luxOnService.address,
      );
  await gachaMachineByGachaTicket.deployed();
  console.log("GachaMachineByGachaTicket Contract address:", gachaMachineByGachaTicket.address);
  console.log("------------------------------------------------");

  console.log("11. gachaMachine deploy start");
  const gachaMachine =
    await (await ethers.getContractFactory("GachaMachine"))
      .deploy(
        dspGachaData.address,
        dspCharacterData.address,
        lct.address,
      );
  await gachaMachine.deployed();
  console.log("GachaMachine Contract address:", gachaMachine.address);
  console.log("------------------------------------------------");

  return {
    luxOnAdmin: luxOnAdmin,
    luxOnService: luxOnService,
    dspGachaData: dspGachaData,
    gachaTicket: gachaTicket,
    airdropUser: airdropUser,
    airdropGachaTicket: airdropGachaTicket,
    dspCharacterData: dspCharacterData,
    lct: lct,
    erc721Centralization: erc721Centralization,
    gachaMachineByGachaTicket: gachaMachineByGachaTicket,
    gachaMachine: gachaMachine
  };
}