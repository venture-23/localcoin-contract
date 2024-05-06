import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function recipientTransfer() {
    const { keypair, client } = getExecStuff();

    const packageId = process.env.PACKAGE_ID || '';
    const localCoinApp = process.env.LOCAL_COIN_APP || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';


    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::local_coin::transfer_token_to_recipients`,
        arguments: [
            tx.pure.u64(100000000),
            // address of recipients
            tx.pure.address("0x54191214990d5de162ff9e41d346e9034adb4d63d50230ac31970640b09b64b1"),
            // local coin token
            tx.object('0x514b1abe54acd1ea8b296ebe1a1f1e35b18c8340166b28d74d8a8064855238eb'),
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
}


recipientTransfer();
