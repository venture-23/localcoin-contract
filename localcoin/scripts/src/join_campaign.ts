import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();

// This function is used to join campaign by recipients
async function joinCampaign() {
    const { keypair, client } = getExecStuff();

    const packageId = process.env.PACKAGE_ID || '';
    const campaign = process.env.CAMPAIGN || '';

    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `${packageId}::campaign_management::join_campaign`,
        arguments: [
            
            tx.object(campaign),
            tx.pure.string("Campaign Name222"),
            tx.pure.string("guysowe")
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


joinCampaign();
