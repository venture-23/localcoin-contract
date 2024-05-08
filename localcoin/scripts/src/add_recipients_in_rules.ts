import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function addRecipient() {
    const { keypair, client } = getExecStuff();

    const packageId = process.env.PACKAGE_ID || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const tokenPolicyCap = process.env.TOKEN_POLICY_CAP || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::allowlist_rule::add_records`,
        arguments: [
            
            tx.object(tokenPolicy),
            tx.object(tokenPolicyCap),
            // address to add as recipients
            tx.pure([ "0x54191214990d5de162ff9e41d346e9034adb4d63d50230ac31970640b09b64b1", "0x36306131687cf3eea75cf05e17d4919a3d0c605f462591e652834015f466fe1d"])
        ],
        typeArguments: [`${packageId}::local_coin::LOCAL_COIN`]

    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });
    console.log(pt);
    const digest_ = result.digest;
}


addRecipient();
