import { TransactionBlock } from '@mysten/sui.js/transactions';
import * as dotenv from 'dotenv';
import getExecStuff from '../utils/execstuff';
dotenv.config();


async function removeMerchant() {
    const { keypair, client } = getExecStuff("super_admin");

    const packageId = process.env.PACKAGE_ID || '';
    const tokenPolicy = process.env.TOKEN_POLICY || '';
    const merchantAddress = process.env.MERCHANT_ADDRESS || '';
    const local_coin = process.env.LOCAL_COIN_APP || '';


    const tx = new TransactionBlock();
    const pt = tx.moveCall({
        target: `0x9ec2cff9b38f989ee20829c065ddc3058b32ee6680efd0ddc36bf7ecd17731aa::allowlist::remove_merchant`,
        arguments: [
            tx.object("0xfd363387f0b2236f2df633d1f2f4639b8d16a7ce9a5094eede28d5d9189dfd3f"),
            tx.object("0xed7a34227ef5e804f12c6158bf1de6b1f7f69acda38e4cd210e84fdeca1bea54"),
            tx.pure.address("0x3a01baa181e0f00d516b8153e2b78351ce495fb6a4da6e0d44421bfe60baed83"),
        ],

    });

    const result = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
    });
    console.log({ result });   
}


removeMerchant();
