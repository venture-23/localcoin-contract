import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function requestSettlement() {
    const { keypair, client } = getExecStuff("merchant");

    const packageId = process.env.PACKAGE_ID || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const localCoinApp = process.env.LOCAL_COIN_APP || '';
    const usdcTreasury = process.env.USDC_TREASURY || '';
    const localCoinToken = process.env.LC_TOKEN_RECIPIENT || '';
    const usdcType = process.env.USDC_TYPE || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::campaign_management::request_settlement`,
        arguments: [
            tx.object(usdcTreasury),
            tx.object(localCoinApp),
            // token to burn
            tx.object(localCoinToken),
            tx.object(tokenPolicy)
        ],
        typeArguments: [usdcType]

    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });   
}


requestSettlement();
