import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function verifyMerchants() {
    const { keypair, client } = getExecStuff();

    const packageId = process.env.PACKAGE_ID || '';
    const merchantRegistry = process.env.MERCHANT_REGISTRY || '';
    const superAdmin = process.env.SUPER_ADMIN || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const localCoinApp = process.env.LOCAL_COIN_APP || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::registry::verify_merchant`,
        arguments: [
            tx.object(superAdmin),
            tx.object(merchantRegistry),
            tx.object(tokenPolicy),
            tx.object(localCoinApp),
            // address of merchants
            tx.pure.address("0x54191214990d5de162ff9e41d346e9034adb4d63d50230ac31970640b09b64b1")
        ],
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
    let output: any;
    output = txn.objectChanges;
}


verifyMerchants();
