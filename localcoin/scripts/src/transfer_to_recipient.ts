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
            tx.pure.u64(1000_000),
            // address of recipients
            tx.pure.address("0x36306131687cf3eea75cf05e17d4919a3d0c605f462591e652834015f466fe1d"),
            // local coin token
            tx.object('0x35a09df94a8b84caeedb9de8c40ea23cba4f02dfc3790129ff1b6eca949af37d'),
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
