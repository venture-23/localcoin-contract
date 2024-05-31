import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function addRecipient() {
    const { keypair, client } = getExecStuff("super_admin");

    const packageId = process.env.PACKAGE_ID || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const tokenPolicyCap = process.env.TOKEN_POLICY_CAP || '';
    const recipientAddress = process.env.RECIPIENT_ADDRESS || '';
    const merchantAddress = process.env.MERCHANT_ADDRESS || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::allowlist_rule::add_records`,
        arguments: [
            
            tx.object(tokenPolicy),
            tx.object(tokenPolicyCap),
            // address to add as recipients
            tx.pure([ recipientAddress, merchantAddress])
        ],
        typeArguments: [`${packageId}::local_coin::LOCAL_COIN`]

    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });
}


addRecipient();
