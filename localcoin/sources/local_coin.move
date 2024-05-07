module localcoin::local_coin {
    use sui::coin::{Self, TreasuryCap, Coin};
    use sui::tx_context::{sender};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;

    use sui::token::{Self, TokenPolicy, TokenPolicyCap, Token};

    use localcoin::allowlist_rule::{Self  as allowlist, Allowlist};
    use localcoin::spendlist_rule::{Self  as spendlist, Spendlist};
    
    /// OTW and the type for the Token.
    public struct LOCAL_COIN has drop {}

    public struct LocalCoinApp has key {
        id: UID,
        /// The treasury cap for the `LocalCoinApp`.
        local_coin_treasury: TreasuryCap<LOCAL_COIN>,
        /// admin for the localCoinApp
        admin: address,
        /// The SUI balance of the app;
        balance: Balance<SUI>,
    }

    fun init(otw: LOCAL_COIN, ctx: &mut TxContext) {
        let treasury_cap = create_currency(otw, ctx);
        let (mut policy, cap) = token::new_policy(&treasury_cap, ctx);

        set_rules(&mut policy, &cap, ctx);
        let sender = ctx.sender();
        
        transfer::public_transfer(cap, sender);
        token::share_policy(policy);

        sui::transfer::share_object(LocalCoinApp {
            id: object::new(ctx),
            local_coin_treasury: treasury_cap,
            admin: sender,
            balance: balance::zero()
        });
        
    }

    public(package) fun set_rules<T>(
        policy: &mut TokenPolicy<T>,
        cap: &TokenPolicyCap<T>,
        ctx: &mut TxContext
    ) {
        token::add_rule_for_action<T, Allowlist>(policy, cap, token::from_coin_action(), ctx);
        token::add_rule_for_action<T, Allowlist>(policy, cap, token::transfer_action(), ctx);

        token::add_rule_for_action<T, Spendlist>(policy, cap, token::spend_action(), ctx);
        token::add_rule_for_action<T, Spendlist>(policy, cap, token::from_coin_action(), ctx);

    }

    fun create_currency<T: drop>(
        otw: T,
        ctx: &mut TxContext
    ): TreasuryCap<T> {
        let (treasury_cap, metadata) = coin::create_currency(
            otw, 9,
            b"LC",
            b"Local Coin",
            b"Coin that illustrates different regulatory requirements",
            option::none(),
            ctx
        );

        transfer::public_freeze_object(metadata);
        treasury_cap
    }

    public fun transfer_token_to_recipients(
        amount: u64,
        recipient: address,
        reg: &mut Token<LOCAL_COIN>,
        policy : &TokenPolicy<LOCAL_COIN>,
        ctx: &mut TxContext
    ) {
        let splitted_amount = token::split(reg, amount, ctx);
        let mut req = token::transfer(splitted_amount, recipient, ctx);
        allowlist::verify(policy, &mut req, ctx);
        token::confirm_request(policy, req, ctx);
    }

    public fun transfer_token_to_merchants(
        merchant: address,
        reg: Token<LOCAL_COIN>,
        policy : &TokenPolicy<LOCAL_COIN>,
        ctx: &mut TxContext
    ) {
        let mut req = token::transfer(reg, merchant, ctx);
        allowlist::verify(policy, &mut req, ctx);
        token::confirm_request(policy, req, ctx);
    }

    public(package) fun spend_token_from_merchant(
        reg: Token<LOCAL_COIN>,
        policy : &mut TokenPolicy<LOCAL_COIN>,
        ctx: &mut TxContext
    ) {
        let mut req = token::spend(reg, ctx);
        spendlist::verify(policy, &mut req, ctx);
        token::confirm_request_mut(policy, req, ctx);
    }

    public(package) fun mint_tokens(
        app: &mut LocalCoinApp,
        payment: Coin<SUI>,
        amount: u64,
        ctx: &mut TxContext
    ) {

        let token = token::mint(&mut app.local_coin_treasury, amount, ctx);
        let request = token::transfer(token, ctx.sender(), ctx);

        token::confirm_with_treasury_cap(&mut app.local_coin_treasury, request, ctx);
        coin::put(&mut app.balance, payment);
    }

    public(package) fun transfer_tokens_to_super_admin(
        app: &mut LocalCoinApp,
        amount: u64,
        ctx: &mut TxContext
    ) {
        transfer::public_transfer(coin::take(&mut app.balance, amount, ctx), app.admin);
    }

}
