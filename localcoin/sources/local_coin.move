module localcoin::local_coin {

    // === Imports ===

    use sui::coin::{Self, TreasuryCap, Coin};
    use sui::tx_context::{sender};
    use sui::balance::{Self, Balance};
    use sui::token::{Self, TokenPolicy, TokenPolicyCap, Token};

    use localcoin::allowlist::{Self  as allow_list, AllowList};

    // === Errors ===

    const ESenderNotAdmin:u64 = 66;

    // === Structs ===
    
    /// OTW and the type for the Token.
    public struct LOCAL_COIN has drop {}

    /// LocalCoinApp stores the treasury cap of the LocalCoin token and also holds the admin address.
    public struct LocalCoinApp has key {
        id: UID,
        /// The treasury cap for the `LocalCoinApp`.
        local_coin_treasury: TreasuryCap<LOCAL_COIN>,
        /// token policy cap 
        token_policy_cap: TokenPolicyCap<LOCAL_COIN>,
        /// admin for the localCoinApp
        admin: address,
    }

    /// This holds the total USDC sent through the app while creating a campaign.   
    public struct UsdcTreasury<phantom T> has key {
        id: UID,
        balance: Balance<T>
    }

    // === Init Function ===

    fun init(otw: LOCAL_COIN, ctx: &mut TxContext
    ) {
        let sender = ctx.sender();
        let treasury_cap = create_currency(otw, ctx);

        // Creating a new policy for the token.
        let (mut policy, cap) = token::new_policy(&treasury_cap, ctx);

        // Adding rules in the token policy.
        set_rules(&mut policy, &cap, ctx);
        
        token::share_policy(policy); 
        sui::transfer::share_object(LocalCoinApp {
            id: object::new(ctx),
            local_coin_treasury: treasury_cap,
            token_policy_cap: cap,
            admin: sender,
        })
    }

    // === Private Functions ===

    fun set_rules<T>(
        policy: &mut TokenPolicy<T>,
        cap: &TokenPolicyCap<T>,
        ctx: &mut TxContext
    ) {
        token::add_rule_for_action<T, AllowList>(policy, cap, token::transfer_action(), ctx);
        token::add_rule_for_action<T, AllowList>(policy, cap, token::spend_action(), ctx);
    }

    fun create_currency<T: drop>(
        otw: T,
        ctx: &mut TxContext
    ): TreasuryCap<T> {
        let (treasury_cap, metadata) = coin::create_currency(
            otw, 9,
            b"LC",
            b"Local Coin",
            b"Coin that illustrates a closed cycle token system",
            option::none(),
            ctx
        );

        transfer::public_freeze_object(metadata);
        treasury_cap
    }

    // === Admin Functions ===
    
    /// Initializing USDC treasury by creating a object. This function should only be called by the
    /// deployer of the package.
    public fun register_token<T>(
        app: &LocalCoinApp,
        ctx: &mut TxContext
    ) {
        let sender = ctx.sender();
        assert!(sender == app.admin, ESenderNotAdmin);
        sui::transfer::share_object(UsdcTreasury<T> {
            id: object::new(ctx),
            balance: balance::zero<T>()
        });
    }

    // === Public-Mutative Functions ===

    /// Recipient uses this function to transfer the tokens to merchants.
    public fun transfer_token_to_merchants(
        amount: u64,
        merchant: address,
        local_coin_token: &mut Token<LOCAL_COIN>,
        policy : &TokenPolicy<LOCAL_COIN>,
        ctx: &mut TxContext
    ) {
        let splitted_amount = token::split(local_coin_token, amount, ctx);
        let mut req = token::transfer(splitted_amount, merchant, ctx);

        // Verify that the transfer is done by the recipient and the receiver is merchant.
        allow_list::verify_recipient_to_merchant_transfer(policy, &mut req, ctx);
        token::confirm_request(policy, req, ctx);
    }

    /// Function to remove merchants from the bag.
    public fun remove_merchant(
        policy: &mut TokenPolicy<LOCAL_COIN>,
        merchant: address,
        app: &LocalCoinApp,
        ctx: &mut TxContext
    ) {
        // only admin of the token can call this function
        assert!(ctx.sender() == app.admin, ESenderNotAdmin);
        allow_list::remove_merchant(policy, &app.token_policy_cap, merchant);
    }

    // /// Function to remove merchants from the bag.
    public fun remove_recipient(
        policy: &mut TokenPolicy<LOCAL_COIN>,
        recipient: address,
        app: &LocalCoinApp,
        ctx: &mut TxContext
    ) {
        // only admin of the token can call this function
        assert!(ctx.sender() == app.admin, ESenderNotAdmin);
        allow_list::remove_recipient(policy, &app.token_policy_cap, recipient);
    }

    // /// Function to remove merchants from the bag.
    public fun remove_campaign_creator(
        policy: &mut TokenPolicy<LOCAL_COIN>,
        campaign_creator: address,
        app: &LocalCoinApp,
        ctx: &mut TxContext
    ) {
        // only admin of the token can call this function
        assert!(ctx.sender() == app.admin, ESenderNotAdmin);
        allow_list::remove_campaign_creator(policy, &app.token_policy_cap, campaign_creator);
    }

    // === Public-Package Functions ===

    /// Campaign Creator uses this function to transfer the tokens to recipients.
    public(package) fun transfer_to_recipients(
        amount: u64,
        recipient: address,
        local_coin_token: &mut Token<LOCAL_COIN>,
        policy : &TokenPolicy<LOCAL_COIN>,
        ctx: &mut TxContext
    ) {
        let splitted_amount = token::split(local_coin_token, amount, ctx);
        let mut req = token::transfer(splitted_amount, recipient, ctx);

        // Verify that the transfer is done by the campaign creator and the receiver is recipient.
        allow_list::verify_campaign_creator_to_recipient_transfer(policy, &mut req, ctx);
        token::confirm_request(policy, req, ctx);
    }

    /// Merchant uses this function to spend the LocalCoin tokens.
    public(package) fun spend_token_from_merchant(
        local_coin_token: Token<LOCAL_COIN>,
        policy : &mut TokenPolicy<LOCAL_COIN>,
        ctx: &mut TxContext
    ) {
        let mut req = token::spend(local_coin_token, ctx);

        // Verify that the spending of token can only be done by the merchant.
        allow_list::verify_merchant_spending(policy, &mut req, ctx);
        token::confirm_request_mut(policy, req, ctx);
    }

    /// This function will be used to mint the LocalCoin tokens with treasury cap.
    /// It will also add sender in the campaign creator list in the bag.
    /// Campaign Creator will only be able to hold the tokens or send the tokens to recipients.
    public(package) fun mint_tokens<T>(
        app: &mut LocalCoinApp,
        usdc_treasury: &mut UsdcTreasury<T>,
        payment: Coin<T>,
        amount: u64,
        policy: &mut TokenPolicy<LOCAL_COIN>,
        ctx: &mut TxContext
    ) {
        let token = token::mint(&mut app.local_coin_treasury, amount, ctx);
        let request = token::transfer(token, ctx.sender(), ctx);

        token::confirm_with_treasury_cap(&mut app.local_coin_treasury, request, ctx);
        coin::put<T>(&mut usdc_treasury.balance, payment);

        let mut campaign_creator = vector::empty();
        vector::push_back(&mut campaign_creator, ctx.sender());

        // Add sender in the list of campaign creator in the bag.
        allow_list::add_campaign_creator(policy, &app.token_policy_cap, campaign_creator, ctx);
    }

    /// Once the localCoin token is spend , this function will be used to transfer usdc to the merchant.
    public(package) fun transfer_usdc_to_merchant<T>(
        usdc_treasury: &mut UsdcTreasury<T>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        transfer::public_transfer(coin::take(&mut usdc_treasury.balance, amount, ctx), recipient);
    }

    /// The merchant is added to the allow list rule.
    /// Merchant is added in the rule so that we can verify the spending of the token can only be done by merchant.
    public(package) fun add_merchant_to_allow_list(
        policy: &mut TokenPolicy<LOCAL_COIN>,
        addresses: vector<address>,
        app: &LocalCoinApp,
        ctx: &mut TxContext
    ) {
        let LocalCoinApp{
            id: _,
            local_coin_treasury: _,
            token_policy_cap: _,
            admin: _
        } = app;

        // Adding merchant in the allowlist.
        allow_list::add_merchants(policy, &app.token_policy_cap, addresses, ctx);
    }

    /// Adding recipient to the allow list rule.
    /// Recipients can only hold the token or transfer the token to the merchants.
    public(package) fun add_recipient_to_allow_list(
        policy: &mut TokenPolicy<LOCAL_COIN>,
        addresses: vector<address>,
        app: &LocalCoinApp,
        ctx: &mut TxContext
    ) {
        let LocalCoinApp{
            id: _,
            local_coin_treasury: _,
            token_policy_cap: _,
            admin: _
        } = app;

        // Adding recipient in the allow list.
        allow_list::add_recipients(policy, &app.token_policy_cap, addresses, ctx);
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(LOCAL_COIN{}, ctx)
    }

}
