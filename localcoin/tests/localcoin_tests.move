
#[test_only]
module localcoin::localcoin_tests {
    use localcoin::local_coin::{Self, LOCAL_COIN, LocalCoinApp, UsdcTreasury};
    use sui::token::{Self, TokenPolicy, TokenPolicyCap};
    use localcoin::spendlist_rule::{Self};
    use localcoin::allowlist_rule::{Self};
    use sui::sui::SUI;
    use sui::coin;
    use sui::test_scenario;
    use sui::test_utils;

    #[test]
    fun test_localcoin() {
       // Arrange
        let admin = @0xA;
        let creator =@0xB;
        let recipient = @0xC;
        let merchant = @0xD;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))
        };

        // Act
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let policycap = test_scenario::take_from_address<TokenPolicyCap<LOCAL_COIN>>(&scenario, admin);

            let mut merchants = vector::empty<address>();
            vector::push_back(&mut merchants, merchant);

            spendlist_rule::add_records<LOCAL_COIN>(&mut tokenpolicy, &policycap, merchants, test_scenario::ctx(&mut scenario));

            test_scenario::return_to_address(admin, policycap);
            test_scenario::return_shared(tokenpolicy);
        };

        // Act
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let policycap = test_scenario::take_from_address<TokenPolicyCap<LOCAL_COIN>>(&scenario, admin);

            let mut allow_list =  vector::empty<address>();
            vector::push_back(&mut allow_list, merchant);
            vector::push_back(&mut allow_list, recipient);
            vector::push_back(&mut allow_list, creator);

            allowlist_rule::add_records<LOCAL_COIN>(&mut tokenpolicy, &policycap, allow_list, test_scenario::ctx(&mut scenario));

            test_scenario::return_to_address(admin, policycap);
            test_scenario::return_shared(tokenpolicy);
        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            local_coin::register_token<SUI>(&localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
        };

        // Act
        test_scenario::next_tx(&mut scenario, creator);
        {
            let tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let mut token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::transfer_token_to_recipients(10, recipient, &mut token, &tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
            test_utils::destroy(token);
        };

        // Act
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::transfer_token_to_merchants(merchant, token, &tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
        };

        // Act
        test_scenario::next_tx(&mut scenario, merchant);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::spend_token_from_merchant(token, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
        };

        // Act
        test_scenario::next_tx(&mut scenario, merchant);
        {
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);
            let mut usdcTreasury = test_scenario::take_shared<UsdcTreasury<SUI>>(&scenario);
            let token = coin::mint_for_testing<SUI>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::mint_tokens(&mut localCoinApp, &mut usdcTreasury, token, 10, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(usdcTreasury);
        };

        // Act
        test_scenario::next_tx(&mut scenario, merchant);
        {
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);
            let mut usdcTreasury = test_scenario::take_shared<UsdcTreasury<SUI>>(&scenario);

            local_coin::transfer_usdc_to_super_admin(&mut usdcTreasury, &localCoinApp, 10, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(usdcTreasury);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::allowlist_rule::EUserNotAllowed)]
    fun test_transfer_token_to_recipients_fail() {
        // Arrange
        let admin = @0xA;
        let creator =@0xB;
        let recipient = @0xC;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))
        };

        // Act
        test_scenario::next_tx(&mut scenario, creator);
        {
            let tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let mut token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::transfer_token_to_recipients(10, recipient, &mut token, &tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
            test_utils::destroy(token);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::allowlist_rule::EUserNotAllowed)]
    fun test_transfer_token_to_merchants_fail() {
        // Arrange
        let admin = @0xA;
        let recipient = @0xC;
        let merchant = @0xD;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))
        };

        // Act
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::transfer_token_to_merchants(merchant, token, &tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::spendlist_rule::EUserNotAllowed)]
    fun test_spend_token_from_merchant_fail() {
        // Arrange
        let admin = @0xA;
        let merchant = @0xD;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))
        };

        // Act
        test_scenario::next_tx(&mut scenario, merchant);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::spend_token_from_merchant(token, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::spendlist_rule::EUserNotAllowed)]
    fun test_spend_token_from_merchant_with_allow_rule_set_fail() {
        // Arrange
        let admin = @0xA;
        let recipient = @0xB;
        let creator = @0xC;
        let merchant = @0xD;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))
        };

        // Act
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let policycap = test_scenario::take_from_address<TokenPolicyCap<LOCAL_COIN>>(&scenario, admin);

            let mut allow_list =  vector::empty<address>();
            vector::push_back(&mut allow_list, merchant);
            vector::push_back(&mut allow_list, recipient);
            vector::push_back(&mut allow_list, creator);

            allowlist_rule::add_records<LOCAL_COIN>(&mut tokenpolicy, &policycap, allow_list, test_scenario::ctx(&mut scenario));

            test_scenario::return_to_address(admin, policycap);
            test_scenario::return_shared(tokenpolicy);
        };

        // Act
        test_scenario::next_tx(&mut scenario, merchant);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::spend_token_from_merchant(token, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::allowlist_rule::EUserNotAllowed)]
    fun test_transfer_token_to_merchants_without_allow_rule_set_fail() {
        // Arrange
        let admin = @0xA;
        let recipient = @0xB;
        let merchant = @0xD;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))
        };

        // Act
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let policycap = test_scenario::take_from_address<TokenPolicyCap<LOCAL_COIN>>(&scenario, admin);

            let mut merchants = vector::empty<address>();
            vector::push_back(&mut merchants, merchant);

            spendlist_rule::add_records<LOCAL_COIN>(&mut tokenpolicy, &policycap, merchants, test_scenario::ctx(&mut scenario));

            test_scenario::return_to_address(admin, policycap);
            test_scenario::return_shared(tokenpolicy);
        };

        // Act
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::transfer_token_to_merchants(merchant, token, &tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
        };
        test_scenario::end(scenario);
    }
}
