export const OPERATOR = {
    LXN: 'LXN_SUPER_OPERATOR',
    DSP: 'DSP_SUPER_OPERATOR',
    LCT: 'LCT_SUPER_OPERATOR',
    DGT: 'DGT_SUPER_OPERATOR',
    ERC721c: 'ERC721CENTRALIZATION_SUPER_OPERATOR',
    AIRDROP: 'AIRDROP_USER_SUPER_OPERATOR',
    VALUECHIP: 'VALUE_CHIPS_SUPER_OPERATOR',
    STAKING: 'STAKING_SUPER_OPERATOR',
}

export const CONTRACT_ABI = {
    LUX_ON_ADMIN: require('../../artifacts/contracts/Admin/LuxOnAdmin.sol/LuxOnAdmin.json'),
    LUX_ON_SERVICE: require('../../artifacts/contracts/Admin/LuxOnService.sol/LuxOnService.json'),
    CRYSTAL_STAKING: require('../../artifacts/contracts/LUXON/myPage/inventory/crystalStaking.sol/crystalStaking.json'),
    DSP_TOKEN: require('../../artifacts/contracts/LUXON/myPage/token/DSP.sol/Dsp.json'),
    MEMORIAL_CRYSTAL: require('../../artifacts/contracts/LUXON/myPage/inventory/crystal/MemorialCrystal.sol/MemorialCrystal.json'),
}

export const URI = {
    ALCHEMY: 'https://polygon-mumbai.g.alchemy.com/v2/ij6oK1WnX7H9_gnueTzz1QUlSGdzykc1',
}