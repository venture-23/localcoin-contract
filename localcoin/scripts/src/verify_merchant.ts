import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function verifyMerchants() {
    const { keypair, client } = getExecStuff("super_admin");

    const packageId = process.env.PACKAGE_ID || '';
    const merchantRegistry = process.env.MERCHANT_REGISTRY || '';
    const superAdmin = process.env.SUPER_ADMIN || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const localCoinApp = process.env.LOCAL_COIN_APP || '';
    const merchantAddress = process.env.MERCHANT_ADDRESS || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::registry::verify_merchant`,
        arguments: [
            tx.object(superAdmin),
            tx.object(merchantRegistry),
            tx.object(tokenPolicy),
            tx.object(localCoinApp),
            // address of merchants
            tx.pure.address(merchantAddress)
        ],
    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });
}


verifyMerchants();
