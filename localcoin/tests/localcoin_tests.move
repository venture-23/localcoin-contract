#[test_only]
module localcoin::localcoin_tests {
    use localcoin::local_coin::{Self, LOCAL_COIN, LocalCoinApp, UsdcTreasury};
    use sui::token::{Self, TokenPolicy};
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

        // add merchants to allow and spend list
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            let mut merchants = vector::empty<address>();
            vector::push_back(&mut merchants, merchant);

            local_coin::add_merchant_to_allow_and_spend_list(&mut tokenpolicy, merchants, &localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(tokenpolicy);
        };

        // add recipient to allow list
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            let mut allow_list =  vector::empty<address>();
            vector::push_back(&mut allow_list, recipient);

            local_coin::add_recipient_to_allow_list(&mut tokenpolicy, allow_list, &localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(tokenpolicy);
        };

        // register token
        test_scenario::next_tx(&mut scenario, admin);
        {
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            local_coin::register_token<SUI>(&localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
        };

        // mint tokens it is called when creator calls create campaign
        test_scenario::next_tx(&mut scenario, creator);
        {
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);
            let mut usdcTreasury = test_scenario::take_shared<UsdcTreasury<SUI>>(&scenario);
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let token = coin::mint_for_testing<SUI>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::mint_tokens(&mut localCoinApp, &mut usdcTreasury, token, 10, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(usdcTreasury);
            test_scenario::return_shared(tokenpolicy);
        };

        // creator transfers tokens to recipient
        test_scenario::next_tx(&mut scenario, creator);
        {
            let tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let mut token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::transfer_token_to_recipients(10, recipient, &mut token, &tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
            test_utils::destroy(token);
        };

        // recipient transfers tokens to merchants
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::transfer_token_to_merchants(merchant, token, &tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
        };

        // merchant spends the token during settlement
        test_scenario::next_tx(&mut scenario, merchant);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::spend_token_from_merchant(token, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
        };

        // while merchant requests settlement usdc is transferred to super admin
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

    #[test, expected_failure(abort_code = localcoin::local_coin::ESenderNotAdmin)]
    fun test_non_admin_register_token_fail() {
        // Arrange
        let admin = @0xA;
        let non_admin =@0xB;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))
        };

        // non admin tries to register a token, it fails
        test_scenario::next_tx(&mut scenario, non_admin);
        {
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            local_coin::register_token<SUI>(&localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
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

        // transfer tokent to recipient who is not in allowlist
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

        // transfer tokent to merchant who is not in allowlist, it fails
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

        // merchant triest to spend token while it is not in spendlist, it fails
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

        // add recipients and merchant to allow list
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            let mut allow_list =  vector::empty<address>();
            vector::push_back(&mut allow_list, merchant);
            vector::push_back(&mut allow_list, recipient);
            vector::push_back(&mut allow_list, creator);

            local_coin::add_recipient_to_allow_list(&mut tokenpolicy, allow_list, &localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(tokenpolicy);
        };

        // merchant triest to spend token while it is in allow lsit but not in spend list, it fails
        test_scenario::next_tx(&mut scenario, merchant);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::spend_token_from_merchant(token, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::sequential_transfer::ESenderNotCampaignCreator)]
    fun test_sender_not_campaign_creator_fail() {
        // Arrange
        let admin = @0xA;
        let recipient = @0xB;
        let creator = @0xC;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))
        };

        // add recipient and creator to allow list
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            let mut allow_list =  vector::empty<address>();
            vector::push_back(&mut allow_list, recipient);
            vector::push_back(&mut allow_list, creator);

            local_coin::add_recipient_to_allow_list(&mut tokenpolicy, allow_list, &localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(tokenpolicy);
        };

        // non campaign creator tries to send tokens to recipient, it fails
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let mut token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::transfer_token_to_recipients(10, recipient, &mut token, &tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
            test_utils::destroy(token);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::sequential_transfer::EReceiverNotMerchant)]
    fun test_receiver_not_merchant_fail() {
        // Arrange
        let admin = @0xA;
        let recipient = @0xB;
        let creator = @0xC;
        let merchant = @0xD;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))
        };

        // add recipient, merchant and creator to allow list
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            let mut allow_list =  vector::empty<address>();
            vector::push_back(&mut allow_list, recipient);
            vector::push_back(&mut allow_list, creator);
            vector::push_back(&mut allow_list, merchant);

            local_coin::add_recipient_to_allow_list(&mut tokenpolicy, allow_list, &localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(tokenpolicy);
        };

        // recipient transfers token to non merchant, it fails
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::transfer_token_to_merchants(merchant, token, &tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::sequential_transfer::ESenderNotRecipient)]
    fun test_sender_not_recipient_fail() {
        // Arrange
        let admin = @0xA;
        let recipient = @0xB;
        let creator = @0xC;
        let merchant = @0xD;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))
        };

        // add merchant and creator to allow list
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            let mut merchants = vector::empty<address>();
            vector::push_back(&mut merchants, merchant);
            vector::push_back(&mut merchants, creator);

            local_coin::add_merchant_to_allow_and_spend_list(&mut tokenpolicy, merchants, &localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(tokenpolicy);
        };

        // add recipient to allow list
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            let mut allow_list =  vector::empty<address>();
            vector::push_back(&mut allow_list, recipient);

            local_coin::add_recipient_to_allow_list(&mut tokenpolicy, allow_list, &localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(tokenpolicy);
        };

        // creator directly tries to transfer tokens to merchant, it fails
        test_scenario::next_tx(&mut scenario, creator);
        {
            let tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::transfer_token_to_merchants(merchant, token, &tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(tokenpolicy);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::sequential_transfer::EReceiverNotRecipient)]
    fun test_receiver_not_recipient_fail() {
        let admin = @0xA;
        let creator =@0xB;
        let recipient = @0xC;
        let merchant = @0xD;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))
        };

        // add merchant and recipient to allow list
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            let mut merchants = vector::empty<address>();
            vector::push_back(&mut merchants, merchant);
            vector::push_back(&mut merchants, recipient);

            local_coin::add_merchant_to_allow_and_spend_list(&mut tokenpolicy, merchants, &localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(tokenpolicy);
        };

        // register a token
        test_scenario::next_tx(&mut scenario, admin);
        {
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            local_coin::register_token<SUI>(&localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
        };

        // mint tokens through create campaign function
        test_scenario::next_tx(&mut scenario, creator);
        {
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);
            let mut usdcTreasury = test_scenario::take_shared<UsdcTreasury<SUI>>(&scenario);
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let token = coin::mint_for_testing<SUI>(1_000_000_000, test_scenario::ctx(&mut scenario));

            local_coin::mint_tokens(&mut localCoinApp, &mut usdcTreasury, token, 10, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(usdcTreasury);
            test_scenario::return_shared(tokenpolicy);
        };

        // creator tries to transfer tokens to unregistered recipient, it fails
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
}
