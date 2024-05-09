module localcoin::campaign_management {
    use std::string:: {String};
    use sui::coin::{Self, Coin};
    use sui::token::{Self, TokenPolicy, Token};
    use sui::vec_map::{Self, VecMap};
    use localcoin::local_coin::{Self as local_coin, LocalCoinApp, UsdcTreasury, LOCAL_COIN};
    use sui::dynamic_object_field as ofield;

    const MIN_CAMPAIGN_CREATOR_FEE:u64 = 1_000_000;

    const EInsufficientCreatorFee: u64 = 11;
    const EInvalidAmount: u64 = 22;
    const EJoinRequested: u64 = 33;
    const ESenderNotCampaignOwner: u64 = 44;
    const ERecipientLimitReached: u64 = 55;

    public struct Campaigns has key {   
        id: UID
    }

    public struct CampaignDetails has key, store {
        id: UID,
        name: String,
        description: String,
        no_of_recipients: u64,
        unverified_recipients: VecMap<address, String>,
        verified_recipients: VecMap<address, String>,
        location: String,
        creator: address
    }

    fun init(ctx: &mut TxContext) {
        let campaigns = Campaigns {
            id: object::new(ctx)
        };
        transfer::share_object(campaigns);
    }

    public fun create_campaign<T> (
        name: String,
        description: String,
        no_of_recipients: u64,
        location: String,
        payment: Coin<T>,
        app: &mut LocalCoinApp,
        usdc_treasury: &mut UsdcTreasury<T>,
        campaigns: &mut Campaigns,
        ctx: &mut TxContext
    ) {
        let amount = coin::value(&payment);
        assert!(amount >= MIN_CAMPAIGN_CREATOR_FEE, EInsufficientCreatorFee);

        let campaign = CampaignDetails {
            id: object::new(ctx),
            name: name,
            description: description,
            no_of_recipients: no_of_recipients,
            unverified_recipients: vec_map::empty<address, String>(),
            verified_recipients: vec_map::empty<address, String>(),
            location: location,
            creator: ctx.sender()
        };

        local_coin::mint_tokens(app, usdc_treasury, payment, amount, ctx);
        // add campaigns details to dof
        ofield::add(&mut campaigns.id, name, campaign);
    }

    public fun join_campaign (
        campaigns: &mut Campaigns,
        campaign_name: String,
        username: String,
        ctx: &mut TxContext
    ) {
        let sender = ctx.sender();
        let campaign = ofield::borrow_mut<String, CampaignDetails>(&mut campaigns.id, campaign_name);
        assert!(vec_map::contains(& campaign.unverified_recipients, &sender) == false &&
         vec_map::contains(& campaign.verified_recipients, &sender) == false, EJoinRequested);

        vec_map::insert(&mut campaign.unverified_recipients, sender, username);
    }

    public fun verify_recipients (
        campaigns: &mut Campaigns,
        campaign_name: String,
        mut recipients: vector<address>,
        ctx: &mut TxContext
    ) {
        let sender = ctx.sender();
        let campaign = ofield::borrow_mut<String, CampaignDetails>(&mut campaigns.id, campaign_name);

        assert!(campaign.creator == sender, ESenderNotCampaignOwner);
        assert!((vec_map::size(&campaign.verified_recipients) + vector::length(&recipients)) <= campaign.no_of_recipients, ERecipientLimitReached);

        while (vector::length(&recipients) > 0) {
            let recipient = vector::pop_back(&mut recipients);
            let (key, value) = vec_map::remove(&mut campaign.unverified_recipients, &recipient);
            vec_map::insert(&mut campaign.verified_recipients, key, value);
        }
    }

    public fun request_settlement<T>(
        usdc_treasury: &mut UsdcTreasury<T>,
        app: &mut LocalCoinApp,
        token: Token<LOCAL_COIN>,
        policy : &mut TokenPolicy<LOCAL_COIN>,
        ctx: &mut TxContext
    ) {
        let amount = token::value(&token);
        assert!(amount >= 0, EInvalidAmount);

        local_coin::spend_token_from_merchant(token, policy, ctx);

        // transfer equivalent amount to super admin
        local_coin::transfer_tokens_to_super_admin(usdc_treasury, app, amount, ctx);
    }

    public fun get_campaign_details(campaigns: &Campaigns, campaign_name: String): &CampaignDetails {
        ofield::borrow<String, CampaignDetails>(&campaigns.id, campaign_name)
    }

    public fun get_unverified_recipients(campaigns: &Campaigns, campaign_name: String): VecMap<address, String> {
        let campaign = ofield::borrow<String, CampaignDetails>(&campaigns.id, campaign_name);
        campaign.unverified_recipients
    }

    public fun get_verified_recipients(campaigns: &Campaigns, campaign_name: String): VecMap<address, String> {
        let campaign = ofield::borrow<String, CampaignDetails>(&campaigns.id, campaign_name);
        campaign.verified_recipients
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }

}