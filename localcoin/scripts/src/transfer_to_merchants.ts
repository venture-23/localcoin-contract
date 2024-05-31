import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import fs from 'fs';
import path from 'path';
import sleep from '../utils/sleep'
dotenv.config();


async function merchantTransfer() {
    const { keypair, client } = getExecStuff("recipient");

    const packageId = process.env.PACKAGE_ID || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const merchantAddress = process.env.MERCHANT_ADDRESS || '';
    // local coin token object owned by recipient
    const localCoinToken = process.env.LC_TOKEN_RECIPIENT || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::local_coin::transfer_token_to_merchants`,
        arguments: [
            tx.pure.u64(1_000_000),
            tx.pure.address(merchantAddress),
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
    console.log(local_coin);
    const envFilePath = path.resolve(__dirname, '../../.env');
    let envData = fs.readFileSync(envFilePath, 'utf8');

    envData = envData.replace(/^LC_TOKEN_MERCHANT\s*=\s*.*/m, `LC_TOKEN_MERCHANT='${local_coin}'`);
    fs.writeFileSync(envFilePath, envData);

}


merchantTransfer();
