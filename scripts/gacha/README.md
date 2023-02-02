
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
3. npx hardhat run scripts/gacha/deploy.ts

## mumbai 배포된 contract address
```bash
LuxOnAdmin : '0x55b811f15194907FAFeB9B56622f650648aC7c38'
LuxOnService : '0x8C086b6BB0585Bd616E079A681E1682fF5A473Be'
GachaData : '0xAE1EF947F1eCDDdFc5017DECF44c65851Fe05E29'
AirdropUser : '0x0318211Ee4Ead901D64eb6DA34257E018936df5f'
GachaTicket : '0xe72c84C61fA9870D3F2210988d07498c5C93888e'
AirdropGachaTicket : '0x836c7ab9413cc54cdFaFa075C88e374638326ed5'

LCT : '0x096c23A5795a5f9740135Af5e008E65431630bEC'
ERC721Centralization : '0x83609d454573e2734cC3F83FcE2eD16fb47ACA25'
DspCharacterData : '0x021Be2F134ce33222c12e1a6AacB72949f26B26D'
GachaMachineByGachaTicket : '0xB5f45a7fB3466a773E5c10ae03423413AD78DF4d'
GachaMachine : '0x04C95a09b5CB972f027903b4F8Ba12524d6C2eD4'
```