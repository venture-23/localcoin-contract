import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
import { LEGAL_TCP_SOCKET_OPTIONS } from 'mongodb';
dotenv.config();

// This function is used to join campaign by recipients
async function verifyRecipients() {
    const { keypair, client } = getExecStuff("super_admin");

    const packageId = process.env.PACKAGE_ID || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const campaign = process.env.CAMPAIGN || '';
    const localCoinApp = process.env.LOCAL_COIN_APP || '';
    const recipientAddress = process.env.RECIPIENT_ADDRESS || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::campaign_management::verify_recipients`,
        arguments: [
            
            tx.object(campaign),
            tx.pure.string("Campaign Name"),
            tx.pure([recipientAddress]),
            tx.object(tokenPolicy),         
            tx.object(localCoinApp)
        ],

    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });
}


verifyRecipients();
