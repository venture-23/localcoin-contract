import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import sleep from '../utils/sleep'
dotenv.config();
import fs from 'fs';
import path from 'path';

async function createCampaign() {
    const { keypair, client } = getExecStuff("super_admin");

    const packageId = process.env.PACKAGE_ID || '';
    const LocalCoinApp = process.env.LOCAL_COIN_APP || '';
    const usdcTreasury = process.env.USDC_TREASURY || '';
    const campaign = process.env.CAMPAIGN || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const usdcToken = process.env.USDC_FOR_CAMPAIGN || '';
    const usdcType = process.env.USDC_TYPE || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::campaign_management::create_campaign`,
        arguments: [
            tx.pure.string("Campaign Name"),
            tx.pure.string('Campaign Descriptions'),
            tx.pure.u64(10),
            tx.pure.string("Campaign Location"),
            // payment object
            tx.object(usdcToken),
            tx.object(LocalCoinApp),
            tx.object(usdcTreasury),
            tx.object(campaign),
            tx.object(tokenPolicy)
        ],
        typeArguments: [usdcType]

    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });
    console.log(pt);
    const digest_ = result.digest;
    await sleep(40000);

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
    let local_coin;

    for (let i = 0; i < output.length; i++) {
        const item = output[i];
        if (await item.type === 'created') {
            if (await item.objectType === `0x2::token::Token<${packageId}::local_coin::LOCAL_COIN>`) {
                local_coin = String(item.objectId);
            }
        }
    }

    const envFilePath = path.resolve(__dirname, '../../.env');
    let envData = fs.readFileSync(envFilePath, 'utf8');

    envData = envData.replace(/^LC_TOKEN_CAMPAIGN_CREATOR\s*=\s*.*/m, `LC_TOKEN_CAMPAIGN_CREATOR='${local_coin}'`);


    fs.writeFileSync(envFilePath, envData);

}


createCampaign();
