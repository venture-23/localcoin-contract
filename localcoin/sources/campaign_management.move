module localcoin::campaign_management {

    // === Imports ===

    use std::string:: {String};

    use sui::coin::{Self, Coin};
    use sui::token::{Self, TokenPolicy, Token};
    use sui::vec_map::{Self, VecMap};
    use sui::dynamic_object_field as ofield;

    use localcoin::local_coin::{Self as localcoin, LocalCoinApp, UsdcTreasury, LOCAL_COIN};

    // === Constants ===

    const MIN_CAMPAIGN_CREATOR_FEE:u64 = 1_000_000;

    // === Errors ===

    const EInsufficientCreatorFee: u64 = 11;
    const EInvalidAmount: u64 = 22;
    const EJoinRequested: u64 = 33;
    const ESenderNotCampaignOwner: u64 = 44;
    const ERecipientLimitReached: u64 = 55;

    // === Structs ===

    public struct Campaigns has key {   
        id: UID
    }

    /// CampaignDetails Struct stores details of each campaign.
    public struct CampaignDetails has key, store {
        id: UID,
        name: String,
        description: String,
        no_of_recipients: u64,
        unverified_recipients: VecMap<address, String>,
        verified_recipients: VecMap<address, String>,
        recipient_balance: VecMap<address, u64>,
        amount: u64,
        location: String,
        creator: address
    }

    // === Init Function ===

    fun init(ctx: &mut TxContext
    ) {
        let campaigns = Campaigns {
            id: object::new(ctx)
        };
        transfer::share_object(campaigns);
    }

    // === Public-Mutative Functions ===

    /// Campaign Creator will create campaign by sending USDC tokens.
    /// After the tokens are deposited, localCoin will be minted to the campaign creator.
    public fun create_campaign<T> (
        name: String,
        description: String,
        no_of_recipients: u64,
        location: String,
        payment: Coin<T>,
        app: &mut LocalCoinApp,
        usdc_treasury: &mut UsdcTreasury<T>,
        campaigns: &mut Campaigns,
        policy: &mut TokenPolicy<LOCAL_COIN>,
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
            recipient_balance: vec_map::empty<address, u64>(),
            amount: amount,
            location: location,
            creator: ctx.sender()
        };

        localcoin::mint_tokens(app, usdc_treasury, payment, amount, policy, ctx);
        // add campaigns details to dof
        ofield::add(&mut campaigns.id, name, campaign);
    }

    /// Recipients can join the campaign by providing the campaign object that they wanted to join.
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

    // === Protected Functions ===

    /// Campaign Creator can verify the recipients list and let them enter in their campaign.
    public fun verify_recipients (
        campaigns: &mut Campaigns,
        campaign_name: String,
        mut recipients: vector<address>,
        policy: &mut TokenPolicy<LOCAL_COIN>,
        app: &mut LocalCoinApp,
        ctx: &mut TxContext
    ) {
        let sender = ctx.sender();
        let campaign = ofield::borrow_mut<String, CampaignDetails>(&mut campaigns.id, campaign_name);

        assert!(campaign.creator == sender, ESenderNotCampaignOwner);
        assert!((vec_map::size(&campaign.verified_recipients) + vector::length(&recipients)) <= campaign.no_of_recipients, ERecipientLimitReached);

        // The recipient is added in the allow list.
        localcoin::add_recipient_to_allow_list(policy, recipients, app, ctx);
        
        while (vector::length(&recipients) > 0) {
            let recipient = vector::pop_back(&mut recipients);
            let (key, value) = vec_map::remove(&mut campaign.unverified_recipients, &recipient);
            vec_map::insert(&mut campaign.verified_recipients, key, value);
        };

    }

    // Campaign creator transfers tokens to recipients. The recepient balance field gets updated
    // everytime they receive tokens from creator.
    public fun transfer_token_to_recipient (
        campaigns: &mut Campaigns,
        campaign_name: String,
        amount: u64,
        recipient: address,
        reg: &mut Token<LOCAL_COIN>,
        policy : &TokenPolicy<LOCAL_COIN>,
        ctx: &mut TxContext
    ) {
        assert!(amount > 0, EInvalidAmount);

        let campaign = ofield::borrow_mut<String, CampaignDetails>(&mut campaigns.id, campaign_name);
        // let mut recipient_balance_map = campaign.recipient_balance;

        if (vec_map::contains(&campaign.recipient_balance, &recipient)) {
            let (key, val) = vec_map::remove(&mut campaign.recipient_balance, &recipient);
            vec_map::insert(&mut campaign.recipient_balance, key, (val + amount));
        } else {
            vec_map::insert(&mut campaign.recipient_balance, recipient, amount);
        };

        localcoin::transfer_to_recipients(amount, recipient, reg, policy, ctx);
    }

    /// Merchant will request for the settlement once he get LocalCoin tokens from recipients.
    /// The LocalCoin token will be spent and the respective USDC amount will be transferred to
    /// SuperAdmin.
    /// Once SuperAdmin gets the USDC , they will be settling up with the merchants in fiat currency.
    public fun request_settlement<T>(
        usdc_treasury: &mut UsdcTreasury<T>,
        token: Token<LOCAL_COIN>,
        policy : &mut TokenPolicy<LOCAL_COIN>,
        ctx: &mut TxContext
    ) {
        let amount = token::value(&token);
        assert!(amount > 0, EInvalidAmount);

        localcoin::spend_token_from_merchant(token, policy, ctx);

        // transfer equivalent amount to super admin
        localcoin::transfer_usdc_to_merchant(usdc_treasury, amount, ctx.sender(), ctx);
    }

    // === Public-View Functions ===

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

    public fun get_recipients_balance(campaigns: &Campaigns, campaign_name: String): VecMap<address, u64> {
        let campaign = ofield::borrow<String, CampaignDetails>(&campaigns.id, campaign_name);
        campaign.recipient_balance
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }

}