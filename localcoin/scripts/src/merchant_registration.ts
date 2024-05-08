import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function merchantRegistration() {
    const { keypair, client } = getExecStuff();

    const packageId = process.env.PACKAGE_ID || '';
    const merchantRegistry = process.env.MERCHANT_REGISTRY || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::registry::merchant_registration`,
        arguments: [
            tx.pure.string("Merchant Name"),
            tx.pure.string('9819128121'),
            tx.pure.string('Store name'),
            tx.pure.string("Merchant Location"),
            // payment object
            tx.object(merchantRegistry)
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
    let campaign_details;

    for (let i = 0; i < output.length; i++) {
        const item = output[i];
        if (await item.type === 'created') {
            if (await item.objectType === `${packageId}::campaign_management::CampaignDetails`) {
                campaign_details = String(item.objectId);
            }
        }
    }
    console.log(`campaign details : ${campaign_details}`);
}


merchantRegistration();
