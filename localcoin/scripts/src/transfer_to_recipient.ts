import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();
import fs from 'fs';
import path from 'path';
import sleep from '../utils/sleep'

async function recipientTransfer() {
    const { keypair, client } = getExecStuff("super_admin");

    const packageId = process.env.PACKAGE_ID || '';
    const localCoinApp = process.env.LOCAL_COIN_APP || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const recipientAddress = process.env.RECIPIENT_ADDRESS || '';
    const campaign = process.env.CAMPAIGN || '';
    // local coin token object owned by campaign creator
    const localCoinToken = process.env.LC_TOKEN_CAMPAIGN_CREATOR || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::campaign_management::transfer_token_to_recipient`,
        arguments: [
            tx.object(campaign),
            tx.pure.string("Campaign Name"),
            tx.pure.u64(1_000_000),
            // address of recipients
            tx.pure.address(recipientAddress),
            // local coin token
            tx.object(localCoinToken),
            tx.object(tokenPolicy)
        ],
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

    envData = envData.replace(/^LC_TOKEN_RECIPIENT\s*=\s*.*/m, `LC_TOKEN_RECIPIENT='${local_coin}'`);


    fs.writeFileSync(envFilePath, envData);
}


recipientTransfer();
