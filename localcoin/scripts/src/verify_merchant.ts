import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function createCampaign() {
    const { keypair, client } = getExecStuff();

    const packageId = process.env.PACKAGE_ID || '';
    const merchantRegistry = process.env.MERCHANT_REGISTRY || '';
    const superAdmin = process.env.SUPER_ADMIN || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const tokenPolicyCap = process.env.TOKEN_POLICY_CAP || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::registry::verify_merchants`,
        arguments: [
            tx.object(superAdmin),
            tx.object(merchantRegistry),
            tx.object(tokenPolicy),
            tx.object(tokenPolicyCap),
            tx.pure.address("0xe63826bf27e7e596e0842065559d3efbdcdb425cb2e20ea445cda0a4239ce3b6")
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
