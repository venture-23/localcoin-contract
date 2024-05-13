import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function merchantRegistration() {
    const { keypair, client } = getExecStuff("merchant");

    const packageId = process.env.PACKAGE_ID || '';
    const merchantRegistry = process.env.MERCHANT_REGISTRY || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::registry::merchant_registration`,
        arguments: [
            tx.pure.string("Merchant Name"),
            tx.pure.string('9819128121'),
            tx.pure.string('Store name'),
            tx.pure.string("Merchant Location"),
            // payment object
            tx.object(merchantRegistry)
        ],
    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });
}


merchantRegistration();
