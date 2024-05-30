#!/bin/bash

# Execute each script sequentially
echo "Running setup script..."
ts-node scripts/utils/setup.ts

echo "Running register_token script..."
ts-node scripts/src/register_token.ts

echo "Running create_campaign script..."
ts-node scripts/src/create_campaign.ts

echo "Running join_campaign script..."
ts-node scripts/src/join_campaign.ts

echo "Running verify_recipients script..."
ts-node scripts/src/verify_recipients.ts

echo "Running transfer_to_recipient script..."
ts-node scripts/src/transfer_to_recipient.ts

echo "Running merchant_registration script..."
ts-node scripts/src/merchant_registration.ts

echo "Running verify_merchant script..."
ts-node scripts/src/verify_merchant.ts

echo "Running transfer_to_merchants script..."
ts-node scripts/src/transfer_to_merchants.ts

echo "Running request_settlement script..."
ts-node scripts/src/request_settlement.ts

echo "Running remove_merchant script..."
ts-node scripts/src/remove_merchant.ts

echo "Running remove_recipient script..."
ts-node scripts/src/remove_recipient.ts

echo "Running remove_campaign_creator script..."
ts-node scripts/src/remove_campaign_creator.ts

echo "All scripts executed."

