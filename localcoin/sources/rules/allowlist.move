/// A simple Allowlist rule - ensures the token can only be holded by any of the three entities -
///  campaign creator , recipient or merchant.
module localcoin::allowlist {

    // === Imports ===

    use sui::bag::{Self, Bag};
    use sui::token::{
        Self,
        TokenPolicy,
        TokenPolicyCap,
        ActionRequest
    };

    // === Errors ===

    const EUserNotAllowed: u64 = 0;
    const EReceiverNotMerchant: u64 = 1;
    const ESenderNotRecipient: u64 = 2;
    const ESenderNotMerchant: u64 = 3;
    const ESenderNotCampaignCreator: u64 = 4;
    const EReceiverNotRecipient: u64 = 5;

    // === Structs ===

    /// The Rule witness.
    public struct AllowList has drop {}

    // === Public-Package Functions ===

    /// The following function ensures that the token sender must be a recipient 
    /// and the token receiver must be a merchant.
    public(package) fun verify_recipient_to_merchant_transfer<T>(
        policy: &TokenPolicy<T>,
        request: &mut ActionRequest<T>,
        ctx: &mut TxContext
    ) 
    {
        assert!(has_config(policy), EUserNotAllowed);

        let config = config(policy);
        let recipient = token::sender(request);
        let merchant = token::recipient(request);

        // check if the sender is in the list of recipients in the bag.
        assert!(vector::contains(bag::borrow(config, b"recipient".to_string()), &recipient), ESenderNotRecipient);

        if (option::is_some(&merchant)) 
        {
            let merchant = *option::borrow(&merchant);

            // check if the merchant is in the list of merchants in the bag.
            assert!(vector::contains(bag::borrow(config, b"merchant".to_string()), &merchant), EReceiverNotMerchant);
        };

        // Adding approval.
        token::add_approval(AllowList {}, request, ctx);
    }

    /// This function verifies only merchant can spend the token.
    public(package) fun verify_merchant_spending<T>(
        policy: &TokenPolicy<T>,
        request: &mut ActionRequest<T>,
        ctx: &mut TxContext
    ) 
    {
        assert!(has_config(policy), EUserNotAllowed);

        let config = config(policy);
        let recipient = token::sender(request);

        // verify the token spender is merchant.
        assert!(vector::contains(bag::borrow(config, b"merchant".to_string()), &recipient), ESenderNotMerchant);

        // Adding approval.
        token::add_approval(AllowList {}, request, ctx);
    }

    /// The following function ensures that the token sender must be a campaign creator 
    /// and the token receiver must be a recipient.
    public(package) fun verify_campaign_creator_to_recipient_transfer<T>(
        policy: &TokenPolicy<T>,
        request: &mut ActionRequest<T>,
        ctx: &mut TxContext
    ) 
    {
        assert!(has_config(policy), EUserNotAllowed);

        let config = config(policy);
        let campaign_creator = token::sender(request);
        let recipient = token::recipient(request);

        // check if the sender is in the list of campaign creators in the bag.
        assert!(vector::contains(bag::borrow(config, b"campaign_creator".to_string()), &campaign_creator), ESenderNotCampaignCreator);

        if (option::is_some(&recipient)) 
        {
            let recipient = *option::borrow(&recipient);

            // check if the receiver is in the list of recipients in the bag.
            assert!(vector::contains(bag::borrow(config, b"recipient".to_string()), &recipient), EReceiverNotRecipient);
        };

        // Adding approval.
        token::add_approval(AllowList {}, request, ctx);
    }

    /// Adds merchant addresses in the list of merchants in the bag.
    public(package) fun add_merchants<T>(
        policy: &mut TokenPolicy<T>,
        cap: &TokenPolicyCap<T>,
        mut merchants: vector<address>,
        ctx: &mut TxContext,
    ) {
        if (!has_config(policy)) {
            token::add_rule_config(AllowList {}, policy, cap, bag::new(ctx), ctx);
        };

        let config_mut = config_mut(policy, cap);
        let mut _merchant_list = vector::empty();
        
        // If the merchant key already exists in the bag, remove the previous vector of addresses.
        // Then, create a new vector of addresses containing the previous list and add the parameter data.
        let exist_already = bag::contains(config_mut,  b"merchant".to_string());
        if (exist_already)
        {
            _merchant_list = bag::remove(config_mut, b"merchant".to_string());
            let merchant = vector::pop_back(&mut merchants);
            vector::push_back(&mut _merchant_list, merchant);
            bag::add(config_mut, b"merchant".to_string(), _merchant_list);
        }
        else 
        {

            // If the key doesn't exist initialize a bag with vector of addresses from the parameter.
            bag::add(config_mut, b"merchant".to_string(), merchants);
        };
    }

    /// Adds campaign creator addresses in the list of campaign creator in the bag.
    public(package) fun add_campaign_creator<T>(
        policy: &mut TokenPolicy<T>,
        cap: &TokenPolicyCap<T>,
        mut addresses: vector<address>,
        ctx: &mut TxContext,
    ) 
    {
        if (!has_config(policy)) 
        {
            token::add_rule_config(AllowList {}, policy, cap, bag::new(ctx), ctx);
        };

        let config_mut = config_mut(policy, cap);
        let mut _campaign_creators = vector::empty();
        
        // If the campaign_creator key already exists in the bag, remove the previous vector of addresses.
        // Then, create a new vector of addresses containing the previous list and add the parameter data.
        let exist_already = bag::contains(config_mut,  b"campaign_creator".to_string());
        if (exist_already)
        {
            _campaign_creators = bag::remove(config_mut, b"campaign_creator".to_string());
                
            let creator_address = vector::pop_back(&mut addresses);
            let already_in_list = vector::contains(&_campaign_creators, &creator_address);

            // If the address is already in the list of campaign creator then skip
            if (!already_in_list)
            {
                vector::push_back(&mut _campaign_creators, creator_address);
            };
            bag::add(config_mut, b"campaign_creator".to_string(), _campaign_creators);
        }
        else {
            bag::add(config_mut, b"campaign_creator".to_string(), addresses);
        };
        
    }

    /// Adds recipient addresses in the list of recipient in the bag.
    public(package) fun add_recipients<T>(
        policy: &mut TokenPolicy<T>,
        cap: &TokenPolicyCap<T>,
        mut addresses: vector<address>,
        ctx: &mut TxContext,
    ) 
    {
        if (!has_config(policy)) 
        {
            token::add_rule_config(AllowList {}, policy, cap, bag::new(ctx), ctx);
        };

        let config_mut = config_mut(policy, cap);
        let mut _recipient_list = vector::empty();
        
        let exist_already = bag::contains(config_mut,  b"recipient".to_string());
        // If the recipient key already exists in the bag, remove the previous vector of addresses.
        // Then, create a new vector of addresses containing the previous list and add the parameter data.
        if (exist_already)
        {
            _recipient_list = bag::remove(config_mut, b"recipient".to_string());
            while (vector::length(&addresses) > 0) 
            {
                
                let recipient_address = vector::pop_back(&mut addresses);
                let already_in_list = vector::contains(&_recipient_list, &recipient_address);
                // If the address is already in the list of recipient then skip
                if (!already_in_list)
                    {
                        vector::push_back(&mut _recipient_list, recipient_address);
                    };
                bag::add(config_mut, b"recipient".to_string(), _recipient_list);
            
            }
        }
        else {
            bag::add(config_mut, b"recipient".to_string(), addresses);
        };
        

    }

    /// Removes records from the `AllowList rule` for a given action. The Policy
    /// owner can batch-remove records.
    public fun remove_records<T>(
        policy: &mut TokenPolicy<T>,
        cap: &TokenPolicyCap<T>,
        mut addresses: vector<address>,
    ) {
        let config_mut = config_mut(policy, cap);

        while (vector::length(&addresses) > 0) {
            let record = vector::pop_back(&mut addresses);
            let _: bool = bag::remove(config_mut, record);
        };
    }

    // === Internal ===

    fun has_config<T>(self: &TokenPolicy<T>): bool {
        token::has_rule_config_with_type<T, AllowList, Bag>(self)
    }

    fun config<T>(self: &TokenPolicy<T>): &Bag {
        token::rule_config<T, AllowList, Bag>(AllowList {}, self)
    }

    fun config_mut<T>(self: &mut TokenPolicy<T>, cap: &TokenPolicyCap<T>): &mut Bag {
        token::rule_config_mut(AllowList {}, self, cap)
    }
}