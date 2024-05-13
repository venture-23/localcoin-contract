/// Module: localcoin
module localcoin::registry {

    // === Imports ===

    use std::string:: {String};

    use sui::dynamic_object_field as ofield;
    use sui::token::{TokenPolicy};

    use localcoin::local_coin::{Self as localcoin, LOCAL_COIN, LocalCoinApp};

    // === Errors ===

    const ERegistrationRequested: u64 = 101;
    const ENoRegistrationRequest: u64 = 202;
    const EMerchantsAlreadyVerified: u64 = 303;

    // === Structs ===

    /// SuperAdminCap is the capability object that SuperAdmin holds.
    public struct SuperAdminCap has key {
        id: UID
    }

    /// MerchantRegistry stores all the merchant details associated with LocalCoin.
    public struct MerchantRegistry has key {
        id: UID,
        unverified_merchants_count: u64,
        unverified_merchants: vector<address>,
        verified_merchants_count: u64,
        verified_merchants: vector<address>
    }

    /// MerchantDetails stores the details of an individual merchant.
    public struct MerchantDetails has key, store {
        id: UID,
        verified_status: bool,
        merchant_addr: address,
        proprietor: String,
        phone_no: String,
        store_name: String,
        location: String
    }

    // === Init Function ===

    fun init(ctx: &mut TxContext) {
        let super_admin = SuperAdminCap {
            id: object::new(ctx)
        };
        transfer::transfer(super_admin, ctx.sender());

        let merchant_reg = MerchantRegistry {
            id: object::new(ctx),
            unverified_merchants: vector::empty<address>(),
            unverified_merchants_count: 0,
            verified_merchants: vector::empty<address>(),
            verified_merchants_count: 0,
        };
        transfer::share_object(merchant_reg);
    }

    // === Public-Mutative Functions ===

    /// Any of the merchant can come and register to be associated with our product using this function.
    public fun merchant_registration (
        proprietor: String, 
        phone_no: String, 
        store_name: String, 
        location: String,
        reg: &mut MerchantRegistry,
        ctx: &mut TxContext
    ) {
        let sender = ctx.sender();
        // verify sender is not in unverified merchant list
        assert!(vector::contains(& reg.unverified_merchants, &sender) == false &&
         vector::contains(& reg.verified_merchants, &sender) == false, ERegistrationRequested);

        let merchant_details = MerchantDetails {
            id: object::new(ctx),
            verified_status: false,
            merchant_addr: sender,
            proprietor: proprietor,
            phone_no: phone_no,
            store_name: store_name,
            location: location
        };

        // add sender to unverified merchants list
        vector::push_back(&mut reg.unverified_merchants, sender);
        reg.unverified_merchants_count = reg.unverified_merchants_count + 1;

        // add merchants details to dof
        ofield::add(&mut reg.id, sender, merchant_details);
    }

    // === Admin Functions ===

    /// SuperAdmin verifies the merchant using this function.
    /// Once the merchant is verified they will be associated with our product.
    public fun verify_merchant (
        _: &SuperAdminCap, 
        reg: &mut MerchantRegistry,
        policy: &mut TokenPolicy<LOCAL_COIN>,
        app: &mut LocalCoinApp,
        merchant_address: address,
        ctx: &mut TxContext
    ) {
        // verify merchant address is in unverified list
        assert!(vector::contains(& reg.unverified_merchants, &merchant_address) == true, ENoRegistrationRequest);
        // verify merchant is already verified
        assert!(vector::contains(& reg.verified_merchants, &merchant_address) == false, EMerchantsAlreadyVerified);

        let merchant_details = ofield::borrow_mut<address, MerchantDetails>(&mut reg.id, merchant_address);
        // update verified status to true
        merchant_details.verified_status = true;

        // add merchant address to verified merchant list
        vector::push_back(&mut reg.verified_merchants, merchant_address);
        reg.verified_merchants_count = reg.verified_merchants_count + 1;

        let mut merchant_list = vector::empty();
        vector::push_back(&mut merchant_list, merchant_address);

        // add merchant address in both allowlist as well as spendlist
        localcoin::add_merchant_to_allow_and_spend_list(policy, merchant_list, app, ctx);

        // remove merchant address from unverified merchant list
        let (_ , index) = vector::index_of(& reg.unverified_merchants, &merchant_address);
        vector::remove(&mut reg.unverified_merchants, index);
        reg.unverified_merchants_count = reg.unverified_merchants_count - 1;
    }

    /// SuperAdmin can use this function to update the merchant info
    ///  if any merchant submits the false details while registering to be the merchant.
    public fun update_merchant_info (
        _: &SuperAdminCap, 
        reg: &mut MerchantRegistry,
        verified_status: bool,
        merchant_addr: address,
        proprietor: String, 
        phone_no: String, 
        store_name: String, 
        location: String
    ) {
        assert!(vector::contains(& reg.unverified_merchants, &merchant_addr) == true ||
         vector::contains(& reg.verified_merchants, &merchant_addr) == true, ENoRegistrationRequest);

        let merchant_details = ofield::borrow_mut<address, MerchantDetails>(&mut reg.id, merchant_addr);

        merchant_details.verified_status = verified_status;
        merchant_details.merchant_addr = merchant_addr;
        merchant_details.proprietor = proprietor;
        merchant_details.phone_no = phone_no;
        merchant_details.store_name = store_name;
        merchant_details.location = location;

        if (verified_status == false) {
            // if verified status is made false remove merchant from verified list and add it to unverified list
            let (_ , index) = vector::index_of(& reg.verified_merchants, &merchant_addr);
            vector::remove(&mut reg.verified_merchants, index);
            reg.verified_merchants_count = reg.verified_merchants_count - 1;

            // add it back to unverified list
            vector::push_back(&mut reg.unverified_merchants, merchant_addr);
            reg.unverified_merchants_count = reg.unverified_merchants_count + 1;
        };
    }
    
    // === Public-View Functions ===

    public fun get_merchant_info(reg: &mut MerchantRegistry, merchant_address:address): &MerchantDetails {
        ofield::borrow<address, MerchantDetails>(&reg.id, merchant_address)
    }

    public fun get_unverified_merchants(reg: &MerchantRegistry): vector<address> {
        reg.unverified_merchants
    }

    public fun get_verified_merchants(reg: &MerchantRegistry): vector<address> {
        reg.verified_merchants
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }
}

