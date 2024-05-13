import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
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
}


merchantTransfer();
