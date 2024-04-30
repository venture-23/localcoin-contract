module localcoin::campaign_management {
    use std::string:: {String};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::token;
    use sui::sui::SUI;
    use sui::dynamic_object_field as ofield;

    use localcoin::registry::SuperAdmin;
    use localcoin::registry::MerchantRegistry;


    const MIN_CAMPAIGN_CREATOR_FEE:u64 = 1_000_000_000;

    const EInsufficientCreatorFee: u64 = 11;
    const EUnverifiedMerchant: u64 = 22;
    const EInvalidAmount: u64 = 33;


    public struct LOCALCOIN has drop {
        
    }

    public struct ContractTreasury has key {
        id: UID,
        treasury_address: address
    }

    public struct CampaignDetails has key, store {
        id: UID,
        name: String,
        description: String,
        recipients: u64,
        location: String,
        creator: address
    }

    public struct TreasuryCapHolder has key {
        id: UID
    }

    public struct TokenTreasuryCap has key, store {
        id: UID,
        token_symbol: String,
        cap: TreasuryCap<LOCALCOIN>
    }

    fun init(ctx: &mut TxContext) {
        let contract_tresury = ContractTreasury {
            id: object::new(ctx),
            treasury_address: tx_context::sender(ctx)
        };
        transfer::share_object(contract_tresury);
    }

    /// Add tresury cap of tokens in dynamic field
    public fun add_tresury_cap(
        _: &SuperAdmin,
        cap_holder: &mut TreasuryCapHolder,
        cap: TreasuryCap<LOCALCOIN>, 
        token_symbol: String, 
        ctx: &mut TxContext
    ) {
        let token_cap = TokenTreasuryCap {
            id: object::new(ctx),
            token_symbol,
            cap
        };
        ofield::add(&mut cap_holder.id, token_symbol, token_cap);
    }

    public fun create_campaign(
        name: String,
        description: String,
        recipients: u64,
        location: String,
        amount: Coin<SUI>,
        token_symbol: String,
        cap_holder: &mut TreasuryCapHolder,
        contract_tresury: &ContractTreasury,
        ctx: &mut TxContext
        // later change this token type to closed loop token
    ) {
        assert!(coin::value(&amount) >= MIN_CAMPAIGN_CREATOR_FEE, EInsufficientCreatorFee);

        let campaign = CampaignDetails {
            id: object::new(ctx),
            name: name,
            description: description,
            recipients: recipients,
            location: location,
            creator: ctx.sender()
        };

        // get the tresury cap of token from dynamic object field
        let token_tresury_of = ofield::borrow_mut<String, TokenTreasuryCap>(&mut cap_holder.id, token_symbol);
        let token_tresury_cap = &mut token_tresury_of.cap;

        let token = token::mint(token_tresury_cap, coin::value(&amount), ctx);
        let req = token::transfer(token, ctx.sender(), ctx);
        token::confirm_with_treasury_cap(token_tresury_cap, req, ctx);

        transfer::transfer(campaign, ctx.sender());
        transfer::public_transfer(amount, contract_tresury.treasury_address);
    }

    // public fun request_settlement(
    //     cl_token: Coin<LOCALCOIN>,
    //     merchant_registry: &MerchantRegistry,
    //     ctx: &mut TxContext
    // ) {
    //     assert!(coin::value(&cl_token) <= 0, EInvalidAmount);
    //     // assert!(vector::contains(&merchant_registry.verified_merchants, ctx.sender()) == true, EUnverifiedMerchant);

    //     // token::spend(cl_token, ctx);



    // }


}