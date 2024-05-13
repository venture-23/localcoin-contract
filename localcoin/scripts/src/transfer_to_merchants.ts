import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function merchantTransfer() {
    const { keypair, client } = getExecStuff();

    const packageId = process.env.PACKAGE_ID || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';


    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::local_coin::transfer_token_to_merchants`,
        arguments: [
            tx.pure.address("0x54191214990d5de162ff9e41d346e9034adb4d63d50230ac31970640b09b64b1"),
            // local coin token
            tx.object('0xd8fadcf42e0a0bbb09425a5b9f36f3849ed852a3ed629e3a9b766a2d13f37ab4'),
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


merchantTransfer();
