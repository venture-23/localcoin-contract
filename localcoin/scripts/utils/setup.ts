import { SuiObjectChangePublished } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import getExecStuff from './execstuff';
import fs from 'fs';
import path from 'path';
import { log } from 'console';

const { execSync } = require('child_process');

function sleep(ms: number): Promise<void> {
    return new Promise(resolve => {
        setTimeout(resolve, ms);
    });
}

const getPackageId = async () => {
    try {
        const { keypair, client } = getExecStuff();
        const account = "0xe65f125538ff216c12106adfa9004813bba39b5fd58f45f453fb1a866e89c800";
        // const account = "0x7c5b5406c69465c4f09e0c1823fa689c2423697e2c73c120dbfa076d9c9b30ea";
        const packagePath = process.cwd();
        const { modules, dependencies } = JSON.parse(
            execSync(`sui move build --dump-bytecode-as-base64 --path ${packagePath} --skip-fetch-latest-git-deps`, {
                encoding: "utf-8",
            })
        );
        const tx = new TransactionBlock();
        const [upgradeCapp] = tx.publish({
            modules,
            dependencies,
        });
        tx.transferObjects([upgradeCapp], tx.pure(account));
        const result = await client.signAndExecuteTransactionBlock({
            signer: keypair,
            transactionBlock: tx,
            options: {
                showEffects: true,
                showObjectChanges: true,
            }
        });
        console.log(result.digest);
        const digest_ = result.digest;

        const packageId = ((result.objectChanges?.filter(
            (a) => a.type === 'published',
        ) as SuiObjectChangePublished[]) ?? [])[0].packageId.replace(/^(0x)(0+)/, '0x') as string;
        
        let upgradeCap;
        let localCoinApp;
        let superAdmin;
        let tokenPolicy;
        let tokenPolicyCap;
        let merchantRegistry;
        let campaign;

        await sleep(10000);

        if (!digest_) {
            console.log("Digest is not available");
            return { packageId };
        }

        const txn = await client.getTransactionBlock({
            digest: String(digest_),
            options: {
                showEffects: true,
                showInput: false,
                showEvents: false,
                showObjectChanges: true,
                showBalanceChanges: false,
            },
        });
        let output: any;
        output = txn.objectChanges;

        for (let i = 0; i < output.length; i++) {
            const item = output[i];
            if (await item.type === 'created') {
                if (await item.objectType == `0x2::package::UpgradeCap`) {
                    upgradeCap = String(item.objectId);
                }

                if (await item.objectType == `${packageId}::local_coin::LocalCoinApp`) {
                    localCoinApp = String(item.objectId);
                }

                if (await item.objectType == `${packageId}::registry::SuperAdmin`) {
                    superAdmin = String(item.objectId);
                }

                if (await item.objectType == `0x2::token::TokenPolicy<${packageId}::local_coin::LOCAL_COIN>`) {
                    tokenPolicy = String(item.objectId);
                }

                if (await item.objectType == `0x2::token::TokenPolicyCap<${packageId}::local_coin::LOCAL_COIN>`) {
                    tokenPolicyCap = String(item.objectId);
                }

                if (await item.objectType == `${packageId}::registry::MerchantRegistry`) {
                    merchantRegistry = String(item.objectId);
                }
                if (await item.objectType == `${packageId}::campaign_management::Campaigns`) {
                    campaign = String(item.objectId);
                }
                
            }
        }

        // write file in env
        const envFilePath = path.resolve(__dirname, '../../.env');
        let envData = fs.readFileSync(envFilePath, 'utf8');

        envData = envData.replace(/^PACKAGE_ID\s*=\s*.*/m, `PACKAGE_ID='${packageId}'`);
        envData = envData.replace(/^UPGRADE_CAP\s*=\s*.*/m, `UPGRADE_CAP='${upgradeCap}'`);
        envData = envData.replace(/^LOCAL_COIN_APP\s*=\s*.*/m, `LOCAL_COIN_APP='${localCoinApp}'`);
        envData = envData.replace(/^SUPER_ADMIN\s*=\s*.*/m, `SUPER_ADMIN='${superAdmin}'`);
        envData = envData.replace(/^TOKEN_POLICY_CAP\s*=\s*.*/m, `TOKEN_POLICY_CAP='${tokenPolicyCap}'`);
        envData = envData.replace(/^TOKEN_POLICY\s*=\s*.*/m, `TOKEN_POLICY='${tokenPolicy}'`);
        envData = envData.replace(/^MERCHANT_REGISTRY\s*=\s*.*/m, `MERCHANT_REGISTRY='${merchantRegistry}'`);
        envData = envData.replace(/^CAMPAIGN\s*=\s*.*/m, `CAMPAIGN='${campaign}'`);


        fs.writeFileSync(envFilePath, envData);

        return { packageId, upgradeCap, localCoinApp, superAdmin, tokenPolicyCap, tokenPolicy  };
    } catch (error) {
        // Handle potential errors if the promise rejects
        console.error(error);
        return { packageId: '', UpgradeCap: '' };
    }
};

// Call the async function and handle the result.
getPackageId()
    .then((result) => {
        console.log(result);
    })
    .catch((error) => {
        console.error(error);
    });

export default getPackageId;
