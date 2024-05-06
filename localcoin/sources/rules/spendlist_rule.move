// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A simple spendlist rule - allows only the merchant on the merchantlist to
/// perform an Action.
module localcoin::spendlist_rule {
    use sui::bag::{Self, Bag};
    use sui::token::{
        Self,
        TokenPolicy,
        TokenPolicyCap,
        ActionRequest
    };

    /// The `sender` or `recipient` is not on the spendlist.
    const EUserNotAllowed: u64 = 0;

    /// The Rule witness.
    public struct Spendlist has drop {}

    /// Verifies that the sender and the recipient (if set) are both on the
    /// `spendlist_rule` for a given action.
    ///
    /// Aborts if:
    /// - there's no config
    /// - the sender is not on the allowlist
    /// - the recipient is not on the allowlist
    public fun verify<T>(
        policy: &TokenPolicy<T>,
        request: &mut ActionRequest<T>,
        ctx: &mut TxContext
    ) {
        assert!(has_config(policy), EUserNotAllowed);

        let config = config(policy);
        let sender = token::sender(request);
        let recipient = token::recipient(request);

        assert!(bag::contains(config, sender), EUserNotAllowed);

        if (option::is_some(&recipient)) {
            let recipient = *option::borrow(&recipient);
            assert!(bag::contains(config, recipient), EUserNotAllowed);
        };

        token::add_approval(Spendlist {}, request, ctx);
    }

    // === Protected: List Management ===

    /// Adds records to the `spendlist_rule` for a given action. The Policy
    /// owner can batch-add records.
    public fun add_records<T>(
        policy: &mut TokenPolicy<T>,
        cap: &TokenPolicyCap<T>,
        mut addresses: vector<address>,
        ctx: &mut TxContext,
    ) {
        if (!has_config(policy)) {
            token::add_rule_config(Spendlist {}, policy, cap, bag::new(ctx), ctx);
        };

        let config_mut = config_mut(policy, cap);
        while (vector::length(&addresses) > 0) {
            bag::add(config_mut, vector::pop_back(&mut addresses), true)
        }
    }

    /// Removes records from the `spendlist_rule` for a given action. The Policy
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
        token::has_rule_config_with_type<T, Spendlist, Bag>(self)
    }

    fun config<T>(self: &TokenPolicy<T>): &Bag {
        token::rule_config<T, Spendlist, Bag>(Spendlist {}, self)
    }

    fun config_mut<T>(self: &mut TokenPolicy<T>, cap: &TokenPolicyCap<T>): &mut Bag {
        token::rule_config_mut(Spendlist {}, self, cap)
    }
}