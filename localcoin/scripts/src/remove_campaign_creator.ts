import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function removeCreator() {
    const { keypair, client } = getExecStuff("super_admin");

    const packageId = process.env.PACKAGE_ID || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const creatorAddress = process.env.SUPER_ADMIN_ADDRESS || '';
    const local_coin = process.env.LOCAL_COIN_APP || '';


    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::local_coin::remove_campaign_creator`,
        arguments: [
            tx.object(tokenPolicy),
            tx.pure.address(creatorAddress),
            tx.object(local_coin)
        ],

    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });   
}


removeCreator();
