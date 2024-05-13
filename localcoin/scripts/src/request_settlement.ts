import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function requestSettlement() {
    const { keypair, client } = getExecStuff();

    const packageId = process.env.PACKAGE_ID || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const localCoinApp = process.env.LOCAL_COIN_APP || '';
    const usdcTreasury = process.env.USDC_TREASURY || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::campaign_management::request_settlement`,
        arguments: [
            tx.object(usdcTreasury),
            tx.object(localCoinApp),
            // token to burn
            tx.object('0xd8fadcf42e0a0bbb09425a5b9f36f3849ed852a3ed629e3a9b766a2d13f37ab4'),
            tx.object(tokenPolicy)
        ],
        typeArguments: [`0x219d80b1be5d586ff3bdbfeaf4d051ec721442c3a6498a3222773c6945a73d9f::usdc::USDC`]

    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });
    console.log(pt);
    const digest_ = result.digest;

    const txn = await client.getTransactionBlock({
        digest: String(digest_),
        // only fetch the effects and objects field
        options: {
            showEffects: true,
            showInput: false,
            showEvents: false,
            showObjectChanges: true,
            showBalanceChanges: false,
        },
    });
}


requestSettlement();
