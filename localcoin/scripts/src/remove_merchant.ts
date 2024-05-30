import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function removeMerchant() {
    const { keypair, client } = getExecStuff("super_admin");

    const packageId = process.env.PACKAGE_ID || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const merchantAddress = process.env.MERCHANT_ADDRESS || '';
    const local_coin = process.env.LOCAL_COIN_APP || '';


    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::local_coin::remove_merchant`,
        arguments: [
            tx.object(tokenPolicy),
            tx.pure.address(merchantAddress),
            tx.object(local_coin)
        ],

    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });   
}


removeMerchant();
