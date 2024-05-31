import { getFullnodeUrl, SuiClient } from '@mysten/sui.js/client';
import { Ed25519Keypair, } from '@mysten/sui.js/keypairs/ed25519';
import * as dotenv from 'dotenv';
dotenv.config();

const MERCHANT_MNEMONICS = process.env.MERCHANT_MNEMONICS || '';
const SUPER_ADMIN_MNEMONICS = process.env.SUPER_ADMIN_MNEMONICS || '';
const RECIPIENT_MNEMONICS = process.env.RECIPIENT_MNEMONICS || '';

const getExecStuff = (role: string) => {
    let mnemonics;
    
    if (role === "super_admin") {
        mnemonics = SUPER_ADMIN_MNEMONICS;
    } else if (role === "recipient") {
        mnemonics = RECIPIENT_MNEMONICS;
    } else {
        mnemonics = MERCHANT_MNEMONICS;
    }

    const keypair = Ed25519Keypair.deriveKeypair(mnemonics);
    const client = new SuiClient({
        url: getFullnodeUrl('testnet'),
    });
    return { keypair, client };
}

export default getExecStuff;
