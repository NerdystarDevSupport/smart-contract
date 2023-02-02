
1. npm install
2. hardhat.config.ts 파일
```bash
polygon_mumbai: {
      url: 'my alchemy api key',
      accounts: [`0x${'my private key'}`]
    }
```
3. deploy.ts 파일
```bash
export const web3 = createAlchemyWeb3('my alchemy api key');
const PRIVATE_KEY = 'my private key';
```
3. npx hardhat run scripts/gacha-ticket-airdrop/deploy.ts

## mumbai 배포된 contract address
```bash
LuxOnAdmin : '0x55b811f15194907FAFeB9B56622f650648aC7c38'
LuxOnService : '0x8C086b6BB0585Bd616E079A681E1682fF5A473Be'
GachaData : '0xAE1EF947F1eCDDdFc5017DECF44c65851Fe05E29'
AirdropUser : '0x0318211Ee4Ead901D64eb6DA34257E018936df5f'
GachaTicket : '0xe72c84C61fA9870D3F2210988d07498c5C93888e'
AirdropGachaTicket : '0x836c7ab9413cc54cdFaFa075C88e374638326ed5'
```