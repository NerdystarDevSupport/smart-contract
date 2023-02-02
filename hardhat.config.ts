/**
 * @type import('hardhat/config').HardhatUserConfig
 */
// require('dotenv').config();
import "@nomiclabs/hardhat-ethers";
// const { VUE_APP_API_URL, VUE_APP_METAMASK_PRIVATE_KEY } = process.env;
// console.log(process.env.VUE_APP_API_URL)
// console.log(VUE_APP_METAMASK_PRIVATE_KEY)
module.exports = {
  solidity: "0.8.16",
  defaultNetwork: "polygon_mumbai",
  networks: {
    hardhat: {},
    polygon_mumbai: {
      url: '',
      accounts: [`0x${''}`]
    }
  },
  paths: {
    sources: "./contracts",
    artifacts: "./artifacts"
  },
}
