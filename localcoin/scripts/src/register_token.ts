import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import fs from 'fs';
import path from 'path';
dotenv.config();


async function registerToken() {
    const { keypair, client } = getExecStuff();

    const packageId = process.env.PACKAGE_ID || '';
    const LocalCoinApp = process.env.LOCAL_COIN_APP || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::local_coin::register_token`,
        arguments: [
            tx.object(LocalCoinApp)
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
    let usdc_treasury;
    for (let i = 0; i < output.length; i++) {
        const item = output[i];
        console.log(item.type);
        if (await item.type === 'created') {
            console.log(item.objectType);
            if (await item.objectType === `${packageId}::local_coin::UsdcTreasury<0x219d80b1be5d586ff3bdbfeaf4d051ec721442c3a6498a3222773c6945a73d9f::usdc::USDC>`) {
                usdc_treasury = String(item.objectId);
            }
        }
    }
    // write file in env
    const envFilePath = path.resolve(__dirname, '../../.env');
    let envData = fs.readFileSync(envFilePath, 'utf8');

    envData = envData.replace(/^USDC_TREASURY\s*=\s*.*/m, `USDC_TREASURY='${usdc_treasury}'`);

    fs.writeFileSync(envFilePath, envData);
    console.log(`USDC Treasury : ${usdc_treasury}`);
}


registerToken();
