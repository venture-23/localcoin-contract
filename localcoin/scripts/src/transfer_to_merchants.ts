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
            tx.pure.address("0xe63826bf27e7e596e0842065559d3efbdcdb425cb2e20ea445cda0a4239ce3b6"),
            // local coin token
            tx.object('0xe0c25f77848d0fb73b10ee933cea9a0e7072666d9e11ca75a29ecce171f8140e'),
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
