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

        assert!(bag::borrow(config, recipient) == b"recipient".to_string(), ESenderNotRecipient);

        if (option::is_some(&merchant)) {
            let merchant = *option::borrow(&merchant);
            assert!(bag::borrow(config, merchant) == b"merchant".to_string(), EReceiverNotMerchant);
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

        assert!(bag::borrow(config, campaign_creator) == b"campaign_creator".to_string(), ESenderNotCampaignCreator);

        if (option::is_some(&recipient)) {
            let recipient = *option::borrow(&recipient);
            assert!(bag::borrow(config, recipient) == b"recipient".to_string(), EReceiverNotRecipient);
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
        while (vector::length(&merchants) > 0) {
            let merchant = vector::pop_back(&mut merchants);
            let exist_already = bag::contains(config_mut, merchant);
            if (!exist_already){
                bag::add(config_mut, merchant, b"merchant".to_string());
            };
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
        while (vector::length(&addresses) > 0) {
            let address = vector::pop_back(&mut addresses);
            let exist_already = bag::contains(config_mut, address);
            if (!exist_already){
                bag::add(config_mut, address, b"campaign_creator".to_string());
            };
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
        while (vector::length(&addresses) > 0) {
            let address = vector::pop_back(&mut addresses);
            let exist_already = bag::contains(config_mut, address);
            if (!exist_already){
                bag::add(config_mut, address, b"recipient".to_string());
            };
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