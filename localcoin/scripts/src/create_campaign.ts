import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function createCampaign() {
    const { keypair, client } = getExecStuff();

    const packageId = process.env.PACKAGE_ID || '';
    const LocalCoinApp = process.env.LOCAL_COIN_APP || '';
    const usdcTreasury = process.env.USDC_TREASURY || '';
    const campaign = process.env.CAMPAIGN || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::campaign_management::create_campaign`,
        arguments: [
            tx.pure.string("Campaign Name222"),
            tx.pure.string('Campaign Descriptions'),
            tx.pure.u64(10),
            tx.pure.string("Campaign Location"),
            // payment object
            tx.object("0xe33840312ae0a4b9045bf3cf9e44cc66bbc8585f9ed59acccc5653a480328d17"),
            tx.object(LocalCoinApp),
            tx.object(usdcTreasury),
            tx.object(campaign),
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
