import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function createCampaign() {
    const { keypair, client } = getExecStuff();

    const packageId = process.env.PACKAGE_ID || '';
    const LocalCoinApp = process.env.LOCAL_COIN_APP || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::campaign_management::create_campaign`,
        arguments: [
            tx.pure.string("Campaign Name"),
            tx.pure.string('Campaign Descriptions'),
            tx.pure.u64(10),
            tx.pure.string("Campaign Location"),
            // payment object
            tx.object("0x3480525f8aa0df25e130c9e0b8197b2c7206c2458ead863dd89ffc638dc2b308"),
            tx.object(LocalCoinApp)
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


createCampaign();
