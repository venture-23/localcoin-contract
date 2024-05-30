import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function removeRecipient() {
    const { keypair, client } = getExecStuff("super_admin");

    const packageId = process.env.PACKAGE_ID || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const recipientAddress = process.env.RECIPIENT_ADDRESS || '';
    const local_coin = process.env.LOCAL_COIN_APP || '';


    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::local_coin::remove_recipient`,
        arguments: [
            // token to burn
            tx.object(tokenPolicy),
            tx.pure.address(recipientAddress),
            tx.object(local_coin)
        ],

    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });   
}


removeRecipient();
