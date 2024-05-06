module localcoin::campaign_management {
    use std::string:: {String};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::token::{Self, TokenPolicy, TokenPolicyCap, Token};
    use sui::sui::SUI;
    use sui::dynamic_object_field as ofield;
    use localcoin::registry::SuperAdmin;
    use localcoin::registry::MerchantRegistry;
    use localcoin::local_coin::{Self as local_coin, LocalCoinApp, LOCAL_COIN};
    use std::vector::{Self as vector};


    const MIN_CAMPAIGN_CREATOR_FEE:u64 = 1_000_000_000;

    const EInsufficientCreatorFee: u64 = 11;
    const EUnverifiedMerchant: u64 = 22;
    const EInvalidAmount: u64 = 33;

    public struct CampaignDetails has key, store {
        id: UID,
        name: String,
        description: String,
        recipients: u64,
        location: String,
        creator: address
    }

    public fun create_campaign(
        name: String,
        description: String,
        recipients: u64,
        location: String,
        payment: Coin<SUI>,
        app: &mut LocalCoinApp,
        ctx: &mut TxContext
    ) {
        let amount = coin::value(&payment);
        assert!(amount >= MIN_CAMPAIGN_CREATOR_FEE, EInsufficientCreatorFee);

        let campaign = CampaignDetails {
            id: object::new(ctx),
            name: name,
            description: description,
            recipients: recipients,
            location: location,
            creator: ctx.sender()
        };

        local_coin::mint_tokens(app, payment, amount, ctx);

        transfer::transfer(campaign, ctx.sender());
    }

    public fun request_settlement(
        token: Token<LOCAL_COIN>,
        policy : &mut TokenPolicy<LOCAL_COIN>,
        ctx: &mut TxContext
    ) {
        // assert!(coin::value(&token) <= 0, EInvalidAmount);
        // check if user can send 0 token ???
        // let merchants = &merchant_registry;

        local_coin::spend_token_from_merchant(token, policy, ctx);

    }


}