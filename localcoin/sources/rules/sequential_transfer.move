// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A simple SequentialTransfer rule - ensures the token can only be transferred 
/// from one specific entity to another in a predetermined sequence.
module localcoin::sequential_transfer {

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
    const EReceiverNotMerchant: u64 = 7;
    const ESenderNotRecipient: u64 = 77;
    const ESenderNotCampaignCreator: u64 = 777;
    const EReceiverNotRecipient: u64 = 7777;

    // === Structs ===

    /// The Rule witness.
    public struct SequentialTransfer has drop {}

    // === Public-Mutative Functions ===

    /// Verifies that the sender is the recipient and receiver is the merchant.
    /// Aborts if:
    /// - there's no config
    /// - the sender is not the recipient
    /// - the receiver is not the merchant
    public fun verify_recipient_to_merchant_transfer<T>(
        policy: &TokenPolicy<T>,
        request: &mut ActionRequest<T>,
        ctx: &mut TxContext
    ) {
        assert!(has_config(policy), EUserNotAllowed);

        let config = config(policy);
        let recipient = token::sender(request);
        let merchant = token::recipient(request);

        assert!(vector::contains(bag::borrow(config, b"recipient".to_string()), &recipient), ESenderNotRecipient);

        if (option::is_some(&merchant)) {
            let merchant = *option::borrow(&merchant);
            assert!(vector::contains(bag::borrow(config, b"merchant".to_string()), &merchant), EReceiverNotMerchant);
        };

        token::add_approval(SequentialTransfer {}, request, ctx);
    }

    /// Verifies that the sender is the campaign creator and receiver is the recipient.
    /// Aborts if:
    /// - there's no config
    /// - the sender is not the campaign creator
    /// - the receiver is not the recipient
    public fun verify_campaign_creator_to_recipient_transfer<T>(
        policy: &TokenPolicy<T>,
        request: &mut ActionRequest<T>,
        ctx: &mut TxContext
    ) {
        assert!(has_config(policy), EUserNotAllowed);

        let config = config(policy);
        let campaign_creator = token::sender(request);
        let recipient = token::recipient(request);

        assert!(vector::contains(bag::borrow(config, b"campaign_creator".to_string()), &campaign_creator), ESenderNotCampaignCreator);

        if (option::is_some(&recipient)) {
            let recipient = *option::borrow(&recipient);
            assert!(vector::contains(bag::borrow(config, b"recipient".to_string()), &recipient), EReceiverNotRecipient);

        };

        token::add_approval(SequentialTransfer {}, request, ctx);
    }

    // === Protected: List Management ===

    /// Adds merchant addresses to the bag.
    public(package) fun add_merchants<T>(
        policy: &mut TokenPolicy<T>,
        cap: &TokenPolicyCap<T>,
        mut merchants: vector<address>,
        ctx: &mut TxContext,
    ) {
        if (!has_config(policy)) {
            token::add_rule_config(SequentialTransfer {}, policy, cap, bag::new(ctx), ctx);
        };

        let config_mut = config_mut(policy, cap);
        let mut _merchant_list = vector::empty();
        
        let exist_already = bag::contains(config_mut,  b"merchant".to_string());
        if (exist_already){
            _merchant_list = bag::remove(config_mut, b"merchant".to_string());
            
            let merchant = vector::pop_back(&mut merchants);
            vector::push_back(&mut _merchant_list, merchant);
            bag::add(config_mut, b"merchant".to_string(), _merchant_list);
        }
        else {
            bag::add(config_mut, b"merchant".to_string(), merchants);
        };
    }

    /// Adds campaign creator addresses to the bag.
    public(package) fun add_campaign_creator<T>(
        policy: &mut TokenPolicy<T>,
        cap: &TokenPolicyCap<T>,
        mut addresses: vector<address>,
        ctx: &mut TxContext,
    ) {
        if (!has_config(policy)) {
            token::add_rule_config(SequentialTransfer {}, policy, cap, bag::new(ctx), ctx);
        };

        let config_mut = config_mut(policy, cap);
        let mut _campaign_creators = vector::empty();
        
        let exist_already = bag::contains(config_mut,  b"campaign_creator".to_string());
        if (exist_already){
            _campaign_creators = bag::remove(config_mut, b"campaign_creator".to_string());
                
            let creator_address = vector::pop_back(&mut addresses);
            let already_in_list = vector::contains(&_campaign_creators, &creator_address);
            if (!already_in_list){
                vector::push_back(&mut _campaign_creators, creator_address);
            };
            bag::add(config_mut, b"campaign_creator".to_string(), _campaign_creators);
        }
        else {
            bag::add(config_mut, b"campaign_creator".to_string(), addresses);
        };
        
    }

    /// Adds recipient addresses to the bag.
    public(package) fun add_recipients<T>(
        policy: &mut TokenPolicy<T>,
        cap: &TokenPolicyCap<T>,
        mut addresses: vector<address>,
        ctx: &mut TxContext,
    ) {
        if (!has_config(policy)) {
            token::add_rule_config(SequentialTransfer {}, policy, cap, bag::new(ctx), ctx);
        };

        let config_mut = config_mut(policy, cap);
        let mut _recipient_list = vector::empty();
        
        let exist_already = bag::contains(config_mut,  b"recipient".to_string());
        if (exist_already){
            _recipient_list = bag::remove(config_mut, b"recipient".to_string());
            while (vector::length(&addresses) > 0) {
                
            let recipient_address = vector::pop_back(&mut addresses);
            let already_in_list = vector::contains(&_recipient_list, &recipient_address);
            if (!already_in_list){
                vector::push_back(&mut _recipient_list, recipient_address);
            };
            bag::add(config_mut, b"recipient".to_string(), _recipient_list);
            
        }
        }
        else {
            bag::add(config_mut, b"recipient".to_string(), addresses);
           
        };
        

    }

    /// Removes records from the `sequential_transfer rule` for a given action. The Policy
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
        token::has_rule_config_with_type<T, SequentialTransfer, Bag>(self)
    }

    fun config<T>(self: &TokenPolicy<T>): &Bag {
        token::rule_config<T, SequentialTransfer, Bag>(SequentialTransfer {}, self)
    }

    fun config_mut<T>(self: &mut TokenPolicy<T>, cap: &TokenPolicyCap<T>): &mut Bag {
        token::rule_config_mut(SequentialTransfer {}, self, cap)
    }
}