# Localcoin
Social groups often struggle with a big problem: how to make sure money is used properly. Here are some common issues: 

* Not Knowing Where Money Goes: People who give money often don't know how it's spent, which makes them hesitant to donate. 
* Money Might Not Be Used Right: Giving cash directly can lead to it being used in the wrong way, which doesn't help the cause. 
* Money Leaving the Community: If money isn't spent locally, it doesn't help the community as much as it could. 

To tackle these problems, LocalCoin has a smart solution. It's like a special money system that keeps track of where every dollar goes. With LocalCoin: 

* Organizations can make sure money goes where it's needed. 
* Donors can trust their money is used properly. 
* There's less risk of money being wasted or misused. 
* Money stays in the local community, helping it grow. 

LocalCoin is a local currency system built on the SUI platform that creates tokens with custom spending restrictions that can be issued by the campaign owner (backed by an equivalent amount of stablecoin) and spent by the recipients with authorized merchants.

# Entities of LocalCoin

These are the different users of LocalCoin and what they do: 
* Campaign Creators:
Anyone can be a campaign creator. They create campaigns by transferring a certain amount of USDC to our platform. This creates a campaign, and a corresponding amount of LocalCoin tokens are minted. If someone wants to join their campaign, the creator can also approve their request and share more details about the campaign.

* Recipients:
Users can browse through campaigns on our app. If they find one they like, they can request to join it. Once they're in, they take part in the campaign and provide proof of their participation. After the creator verifies this proof, they transfer LocalCoin tokens to the recipients. Recipients can use their LocalCoin tokens with approved merchants.

* Merchants:
Recipients transfer the tokens to the merchants, who then provide goods or products worth the token amount. This ensures that the money given by the campaign creator is spent as intended. Merchants can then burn the LocalCoin token and get the corresponding amount of stablecoin, which completes the cycle. 

* Merchant Onboarding:
We're working on building a network of merchants who sell quality products. For example, we won't onboard merchants who sell cigarettes or alcohol. Only the super admin/ app admin can add merchants to our network.

# Closed Loop Token
A closed loop token is standard in SUI where creators limit where the token is used and custom policies can be added. We have used closed loop token standard of SUI in this project. In LocalCoin module, we have added a rule `AllowList` that ensures: 
* Only recipients, merchants, and campaign creators can hold LocalCoin tokens.
* Recipients receive tokens only from campaign creators. 
* Merchants receive tokens only from recipients. 
* Only merchants can spend the tokens.

Website: https://localcoin.us/

App: https://app.localcoin.us/

# Script Execution Guide
This repository contains a set of scripts to manage various tasks related to campaigns, tokens, and merchants. The main script executes several TypeScript scripts in sequence to perform these tasks.

### Prequisite
* ts-node installed globally or locally in the project

### Running the scripts
1. Clone the repository:

2. Install the dependencies: ``npm install``

3. Set the environment variables in .env file. You need to set `` RECIPIENT_MNEMONICS`` , `` SUPER_ADMIN_MNEMONICS`` and ``MERCHANT_MNEMONICS`` and their address respectively in the `` RECIPIENT_ADDRESS`` , `` SUPER_ADMIN_ADDRESS`` and `` MERCHANT_ADDRESS`` respectively.

4. Run the main script using the command``  ./local_coin_script.sh ``.

### Script Details
script executes the following scripts in sequence:

* setup.ts - Sets up initial configurations and deploys the contracts on testnet.
* register_token.ts - Registers a new token. USDC token is registered in this step.
* create_campaign.ts - Creates a new campaign by sending USDC and minting the local coin tokens.
* join_campaign.ts - Recipient can join an existing campaign by sending the request to join.
* verify_recipients.ts - Campaign Creator verifies recipients in the campaign.
* transfer_to_recipient.ts - Transfers funds to a recipient by campaign creator.
* merchant_registration.ts - User registers a new merchant.
* verify_merchant.ts - SuperAdmin verifies a registered merchant.
* transfer_to_merchants.ts - Transfers funds to merchants from the recipients.
* request_settlement.ts - Requests settlement of funds by merchant. Merchant will burn the localCoin and get the equivalent amount of USDC tokens in this transaction.
* remove_merchant.ts - Removes merchant from the bag of LocalCoin.
* remove_recipient.ts - Removes recipient from the bag of LocalCoin.
* remove_campaign_creator.ts - Removes campaign_creator from the bag of LocalCoin.
