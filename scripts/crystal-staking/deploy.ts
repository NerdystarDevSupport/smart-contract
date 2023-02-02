import "@nomiclabs/hardhat-ethers";
import { ethers } from "hardhat";
import { OPERATOR, CONTRACT_ABI } from "../common/enums";
import * as web3 from "../common/web3";

async function deploy() {
    console.log("/////////////////////////////////////////////////////////////////////////////////////////");
    console.log("/////DDDDDDDDDDD//////EEEEEEEEEEE//PPPPPPPPPP////LL///////////////OO//////YY//////YY/////");
    console.log("/////DD////////DD/////EE///////////PP///////PP///LL//////////////OOOO//////YY////YY//////");
    console.log("/////DD/////////DD////EE///////////PP////////PP//LL/////////////OO//OO//////YY//YY///////");
    console.log("/////DD//////////DD///EE///////////PP///////PP///LL////////////OO////OO//////YYYY////////");
    console.log("/////DD///////////DD//EEEEEEEEEEE//PPPPPPPPPP////LL///////////OO//////OO//////YY/////////");
    console.log("/////DD//////////DD///EE///////////PP////////////LL////////////OO////OO///////YY/////////");
    console.log("/////DD/////////DD////EE///////////PP////////////LL/////////////OO//OO////////YY/////////");
    console.log("/////DD////////DD/////EE///////////PP////////////LL//////////////OOOO/////////YY/////////");
    console.log("/////DDDDDDDDDDD//////EEEEEEEEEEE//PP////////////LLLLLLLLLLL//////OO//////////YY/////////");
    console.log("/////////////////////////////////////////////////////////////////////////////////////////");

    // Deploy
    console.log('#################### Deploy Process Start ####################\n');

    console.log('#################### Deploy Contract Start ####################');
    // 1. LuxonAdmin deploy
    console.log('\n#################### 1. LuxonAdmin deploy ####################');
    const luxOnAdmin = await (await ethers.getContractFactory("LuxOnAdmin")).deploy();
    await luxOnAdmin.deployed();
    console.log('LuxOnAdmin Contract Address : ' + luxOnAdmin.address);

    // 2. DSP deploy
    console.log('\n#################### 2. DSP deploy ####################');
    const dsp = await (await ethers.getContractFactory("Dsp")).deploy(OPERATOR.DSP, luxOnAdmin.address);
    await dsp.deployed();
    console.log('DSP Contract Address : ' + dsp.address);

    // 3. Memorial-Crystal deploy
    console.log('\n#################### 3. MemorialCrystal deploy ####################');
    const memorialCrystal = await (await ethers.getContractFactory("MemorialCrystal")).deploy();
    await memorialCrystal.deployed();
    console.log('MemorialCrystal Contract Address : ' + memorialCrystal.address);

    // 4. Crystal-Staking(2, 3) deploy
    console.log('\n#################### 4. CrystalStaking deploy ####################');
    const crystalStaking = await (await ethers.getContractFactory("crystalStaking")).deploy(memorialCrystal.address, dsp.address);
    await crystalStaking.deployed();
    console.log('MemorialCrystal Contract Address : ' + crystalStaking.address);
    console.log('\n#################### Deploy Contract Finish ####################\n');



    // Set Data other contract
    console.log('Set Data other Contract Start\n');
    // 1. approve dsp => staking contract
    console.log('#################### 1. Approve DSP => Staking Contract ####################');
    const dspContract = new web3.Web3Alchemy.Contract(CONTRACT_ABI.DSP_TOKEN.abi, dsp.address);
    let tx = await dspContract.methods.approve(
        crystalStaking.address,
        '10000000000000000000'
    );
    await web3.signAndSendTransaction(dsp, tx);

    // 2. approve mem-cry => staking contract
    console.log('\n#################### 2. Approve Mem-Cry => Staking Contract ####################');
    const memorialCrystalContract = new web3.Web3Alchemy.Contract(CONTRACT_ABI.MEMORIAL_CRYSTAL.abi, memorialCrystal.address);
    tx = await memorialCrystalContract.methods.setApprovalForAll(
        crystalStaking.address,
        true
    );
    await web3.signAndSendTransaction(memorialCrystal, tx);

    // 3. set super-operator
    const luxOnAdminContract = new web3.Web3Alchemy.Contract(CONTRACT_ABI.LUX_ON_ADMIN.abi, luxOnAdmin.address);
    console.log('\n#################### 3. Set Super-Operator ####################');
    tx = await luxOnAdminContract.methods.setSuperOperator(
        OPERATOR.STAKING,
        [web3.account.address],
        true
    );
    await web3.signAndSendTransaction(luxOnAdmin, tx);

    // 4. set Memorial-Crystal Super-Operator
    console.log('\n#################### 4. set Memorial-Crystal Super-Operator ####################');
    tx = memorialCrystalContract.methods.setSuperOperator(
        web3.account.address,
        true,
    );
    await web3.signAndSendTransaction(memorialCrystal, tx);

    // 5. mint Memorial-Crystal
    console.log('\n#################### 5. Mint MemorialCrystal ####################');
    tx = memorialCrystalContract.methods.mint(
        web3.account.address,
        1,
        10,
        0x00
    );
    await web3.signAndSendTransaction(memorialCrystal, tx);
    console.log('\nSet Data other Contract Finish\n');

    // Set Data staking contract
    console.log('Set Data Staking Contract Start\n');

    console.log('!!! Set Super Operator !!!')
    const crystalStakingContract = new web3.Web3Alchemy.Contract(CONTRACT_ABI.CRYSTAL_STAKING.abi, crystalStaking.address);
    tx = await crystalStakingContract.methods.setSuperOperator(
        web3.account.address,
        true
    )
    await web3.signAndSendTransaction(crystalStaking, tx);

    // 1. set tokenIds
    console.log('#################### 1. Set TokenIds ####################');
    tx = await crystalStakingContract.methods.setTokenIds(
        [1,2,3,4,5]
    );
    await web3.signAndSendTransaction(crystalStaking, tx);

    // 2. set weeklySupply
    console.log('\n#################### 2. Set WeeklySupply ####################');
    tx = await crystalStakingContract.methods.setWeeklySupply(
        1500
    );
    await web3.signAndSendTransaction(crystalStaking, tx);

    // 3. set rewardPerPeriods
    console.log('\n#################### 3. Set RewardsPerPeriods ####################');
    tx = await crystalStakingContract.methods.setRewardsPerPeriod(28);
    await web3.signAndSendTransaction(crystalStaking, tx);

    // 4. set lock-up day
    console.log('\n#################### 4. Set LockupDay ####################');
    tx = await crystalStakingContract.methods.setLockUpDay(1);
    await web3.signAndSendTransaction(crystalStaking, tx);

    // 5. fund reward token (DSP)
    console.log('\n#################### 5. Fund Reward Token ####################');
    tx = await crystalStakingContract.methods.fundRewardToken(
        "10000000000000000000"
    );
    await web3.signAndSendTransaction(crystalStaking, tx);

    // 6. set LockUp Fee
    console.log('\n#################### 6. Fund Reward Token ####################');
    tx = await crystalStakingContract.methods.setLockUpFee(
        10
    );
    await web3.signAndSendTransaction(crystalStaking, tx);

    console.log('\nSet Data Staking Contract Finish\n');
}

deploy()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
