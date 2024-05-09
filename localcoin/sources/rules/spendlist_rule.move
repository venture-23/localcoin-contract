/// A simple spendlist rule - allows only the merchant on the merchantlist to
/// spend LocalCoin Token.
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

    /// Verifies that the sender is on the
    /// `spendlist_rule` for sppending of token.
    public fun verify<T>(
        policy: &TokenPolicy<T>,
        request: &mut ActionRequest<T>,
        ctx: &mut TxContext
    ) {
        assert!(has_config(policy), EUserNotAllowed);

        let config = config(policy);
        let sender = token::sender(request);

        assert!(bag::contains(config, sender), EUserNotAllowed);

        token::add_approval(Spendlist {}, request, ctx);
    }

    // === Protected: List Management ===

    /// Adds records to the `spendlist_rule`.
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

    /// Removes records from the `spendlist_rule`.
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