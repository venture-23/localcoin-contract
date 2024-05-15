#[test_only]
module localcoin::campaign_management_tests {
    use localcoin::campaign_management::{Self, Campaigns};
    use localcoin::local_coin::{Self, LOCAL_COIN, LocalCoinApp, UsdcTreasury};
    use sui::token::{Self, TokenPolicy};
    use sui::coin;
    use std::string::{Self};
    use sui::sui::SUI;
    use sui::test_scenario;

    #[test]
    fun test_create_campaign() {
        // Arrange the initial setups
        let admin = @0xA;
        let creator = @0xB;
        let recipient = @0xC;
        let merchant = @0xD;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))

        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            campaign_management::test_init(test_scenario::ctx(&mut scenario))

        };

        // register a token, for test purpose SUI is used, in production we register USDC here
        test_scenario::next_tx(&mut scenario, admin);
        {
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            local_coin::register_token<SUI>(&localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
        };

        // create a first campaign
        test_scenario::next_tx(&mut scenario, creator);
        {
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);
            let mut usdcTreasury = test_scenario::take_shared<UsdcTreasury<SUI>>(&scenario);
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);

            let coin = coin::mint_for_testing<SUI>(1_000_000_000, test_scenario::ctx(&mut scenario));
            campaign_management::create_campaign(string::utf8(b"Test Campaign"), string::utf8(b"Descripton"), 2,
             string::utf8(b"Kathmandu"), coin,  &mut localCoinApp, &mut usdcTreasury, & mut campaigns, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(usdcTreasury);
            test_scenario::return_shared(campaigns);
            test_scenario::return_shared(tokenpolicy);
        };

        // recipient joins first campaign
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            campaign_management::join_campaign(&mut campaigns, string::utf8(b"Test Campaign"), string::utf8(b"Bob"), test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
        };

        // Assert the storage updates
        test_scenario::next_tx(&mut scenario, admin);
        {
            let campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            let mut recipients = vector::empty<address>();
            vector::push_back(&mut recipients, recipient);
            
            assert!(campaign_management::get_unverified_recipients(&campaigns, string::utf8(b"Test Campaign")).keys() == recipients, 0);
            assert!(campaign_management::get_unverified_recipients(&campaigns, string::utf8(b"Test Campaign")).get(&recipient) == string::utf8(b"Bob"), 0);
            assert!(campaign_management::get_unverified_recipients(&campaigns, string::utf8(b"Test Campaign")).size() == 1, 0);
            assert!(campaign_management::get_verified_recipients(&campaigns, string::utf8(b"Test Campaign")).size() == 0, 0);

            test_scenario::return_shared(campaigns);
        };

        // campaign creator verifies the recipients
        test_scenario::next_tx(&mut scenario, creator);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            let mut recipients_list = vector::empty<address>();
            vector::push_back(&mut recipients_list, recipient);

            campaign_management::verify_recipients(&mut campaigns, string::utf8(b"Test Campaign"), recipients_list,
             &mut tokenpolicy, &mut localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
            test_scenario::return_shared(tokenpolicy);
            test_scenario::return_shared(localCoinApp);
        };

        // Assert storage after verifying recipients
        test_scenario::next_tx(&mut scenario, admin);
        {
            let campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            let mut recipients = vector::empty<address>();
            vector::push_back(&mut recipients, recipient);            
            
            assert!(campaign_management::get_unverified_recipients(&campaigns, string::utf8(b"Test Campaign")).size() == 0, 0);
            assert!(campaign_management::get_verified_recipients(&campaigns, string::utf8(b"Test Campaign")).size() == 1, 0);
            
            assert!(campaign_management::get_verified_recipients(&campaigns, string::utf8(b"Test Campaign")).keys() == recipients, 0);
            assert!(campaign_management::get_verified_recipients(&campaigns, string::utf8(b"Test Campaign")).get(&recipient) == string::utf8(b"Bob"), 0);

            test_scenario::return_shared(campaigns);
        };

        // add merchant to allow and spend list
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

        // merchant request for settlement
        test_scenario::next_tx(&mut scenario, merchant);
        {
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);
            let mut usdcTreasury = test_scenario::take_shared<UsdcTreasury<SUI>>(&scenario);
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let token = token::mint_for_testing<LOCAL_COIN>(1_000_000_000, test_scenario::ctx(&mut scenario));

            campaign_management::request_settlement(&mut usdcTreasury, &mut localCoinApp, token, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(usdcTreasury);
            test_scenario::return_shared(tokenpolicy);
        };

        // Assert spent balance after settlement
        test_scenario::next_tx(&mut scenario, admin);
        {
            let tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            assert!(token::spent_balance<LOCAL_COIN>(&tokenpolicy) == 1_000_000_000, 0);
            test_scenario::return_shared(tokenpolicy);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_multiple_campaign() {
        // Arrange setups
        let admin = @0xA;
        let creator = @0xB;
        let creator2 = @0xE;
        let recipient = @0xC;
        let recipient2 = @0xF;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))

        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            campaign_management::test_init(test_scenario::ctx(&mut scenario))

        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            local_coin::register_token<SUI>(&localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
        };

        // create a first campaign
        test_scenario::next_tx(&mut scenario, creator);
        {
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);
            let mut usdcTreasury = test_scenario::take_shared<UsdcTreasury<SUI>>(&scenario);
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);

            let coin = coin::mint_for_testing<SUI>(1_000_000_000, test_scenario::ctx(&mut scenario));
            campaign_management::create_campaign(string::utf8(b"Test Campaign"), string::utf8(b"Descripton"), 2,
             string::utf8(b"Kathmandu"), coin,  &mut localCoinApp, &mut usdcTreasury, & mut campaigns, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(usdcTreasury);
            test_scenario::return_shared(campaigns);
            test_scenario::return_shared(tokenpolicy);
        };

        // create second campaign
        test_scenario::next_tx(&mut scenario, creator2);
        {
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);
            let mut usdcTreasury = test_scenario::take_shared<UsdcTreasury<SUI>>(&scenario);
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);

            let coin = coin::mint_for_testing<SUI>(1_000_000_000, test_scenario::ctx(&mut scenario));
            campaign_management::create_campaign(string::utf8(b"Test Campaign 2"), string::utf8(b"Descripton 2"), 2,
             string::utf8(b"US"), coin,  &mut localCoinApp, &mut usdcTreasury, & mut campaigns, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(usdcTreasury);
            test_scenario::return_shared(campaigns);
            test_scenario::return_shared(tokenpolicy);
        };

        // two recipients join first campaign
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            campaign_management::join_campaign(&mut campaigns, string::utf8(b"Test Campaign"), string::utf8(b"Bob"), test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
        };

        test_scenario::next_tx(&mut scenario, recipient2);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            campaign_management::join_campaign(&mut campaigns, string::utf8(b"Test Campaign"), string::utf8(b"Jack"), test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
        };

        // Assert the storege 
        test_scenario::next_tx(&mut scenario, admin);
        {
            let campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            let mut recipients = vector::empty<address>();
            vector::push_back(&mut recipients, recipient);
            vector::push_back(&mut recipients, recipient2);
            
            assert!(campaign_management::get_unverified_recipients(&campaigns, string::utf8(b"Test Campaign")).keys() == recipients, 0);
            assert!(campaign_management::get_unverified_recipients(&campaigns, string::utf8(b"Test Campaign")).get(&recipient) == string::utf8(b"Bob"), 0);
            assert!(campaign_management::get_unverified_recipients(&campaigns, string::utf8(b"Test Campaign")).size() == 2, 0);
            assert!(campaign_management::get_verified_recipients(&campaigns, string::utf8(b"Test Campaign")).size() == 0, 0);

            test_scenario::return_shared(campaigns);
        };

        // same two recipients join second campaign
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            campaign_management::join_campaign(&mut campaigns, string::utf8(b"Test Campaign 2"), string::utf8(b"Bob"), test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
        };

        test_scenario::next_tx(&mut scenario, recipient2);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            campaign_management::join_campaign(&mut campaigns, string::utf8(b"Test Campaign 2"), string::utf8(b"Jack"), test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
        };

        // Assert the storege 
        test_scenario::next_tx(&mut scenario, admin);
        {
            let campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            let mut recipients = vector::empty<address>();
            vector::push_back(&mut recipients, recipient);
            vector::push_back(&mut recipients, recipient2);
            
            assert!(campaign_management::get_unverified_recipients(&campaigns, string::utf8(b"Test Campaign 2")).keys() == recipients, 0);
            assert!(campaign_management::get_unverified_recipients(&campaigns, string::utf8(b"Test Campaign 2")).get(&recipient) == string::utf8(b"Bob"), 0);
            assert!(campaign_management::get_unverified_recipients(&campaigns, string::utf8(b"Test Campaign 2")).size() == 2, 0);
            assert!(campaign_management::get_verified_recipients(&campaigns, string::utf8(b"Test Campaign 2")).size() == 0, 0);

            test_scenario::return_shared(campaigns);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::campaign_management::EInsufficientCreatorFee)]
    fun test_create_campaign_fail() {
        // Arrange
        let admin = @0xA;
        let creator = @0xB;
        
        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))
        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            campaign_management::test_init(test_scenario::ctx(&mut scenario))

        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            local_coin::register_token<SUI>(&localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
        };

        // create campaign with insufficient campaign creation fee
        test_scenario::next_tx(&mut scenario, creator);
        {
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);
            let mut usdcTreasury = test_scenario::take_shared<UsdcTreasury<SUI>>(&scenario);
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);

            let coin = coin::zero(test_scenario::ctx(&mut scenario));
            campaign_management::create_campaign(string::utf8(b"Test Campaign"), string::utf8(b"Descripton"), 2,
             string::utf8(b"Kathmandu"), coin,  &mut localCoinApp, &mut usdcTreasury, &mut campaigns, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(usdcTreasury);
            test_scenario::return_shared(campaigns);
            test_scenario::return_shared(tokenpolicy);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::campaign_management::EJoinRequested)]
    fun test_double_join_campaign_fail() {
        // Arrange
        let admin = @0xA;
        let creator = @0xB;
        let recipient = @0xC;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))

        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            campaign_management::test_init(test_scenario::ctx(&mut scenario))

        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            local_coin::register_token<SUI>(&localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
        };

        // create campaign
        test_scenario::next_tx(&mut scenario, creator);
        {
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);
            let mut usdcTreasury = test_scenario::take_shared<UsdcTreasury<SUI>>(&scenario);
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);

            let coin = coin::mint_for_testing<SUI>(1_000_000_000, test_scenario::ctx(&mut scenario));
            campaign_management::create_campaign(string::utf8(b"Test Campaign"), string::utf8(b"Descripton"), 2,
             string::utf8(b"Kathmandu"), coin,  &mut localCoinApp, &mut usdcTreasury, & mut campaigns, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(usdcTreasury);
            test_scenario::return_shared(campaigns);
            test_scenario::return_shared(tokenpolicy);
        };

        // recipient join campaign
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            campaign_management::join_campaign(&mut campaigns, string::utf8(b"Test Campaign"), string::utf8(b"Bob"), test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
        };

        // try to join campaign from same address with different name, it fails
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            campaign_management::join_campaign(&mut campaigns, string::utf8(b"Test Campaign"), string::utf8(b"Jack"), test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::campaign_management::ESenderNotCampaignOwner)]
    fun test_non_creator_verify_recipients_fail() {
        // Arrange
        let admin = @0xA;
        let creator = @0xB;
        let recipient = @0xC;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))

        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            campaign_management::test_init(test_scenario::ctx(&mut scenario))

        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            local_coin::register_token<SUI>(&localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
        };

        // create campaign
        test_scenario::next_tx(&mut scenario, creator);
        {
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);
            let mut usdcTreasury = test_scenario::take_shared<UsdcTreasury<SUI>>(&scenario);
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);

            let coin = coin::mint_for_testing<SUI>(1_000_000_000, test_scenario::ctx(&mut scenario));
            campaign_management::create_campaign(string::utf8(b"Test Campaign"), string::utf8(b"Descripton"), 2,
             string::utf8(b"Kathmandu"), coin,  &mut localCoinApp, &mut usdcTreasury, & mut campaigns, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(usdcTreasury);
            test_scenario::return_shared(campaigns);
            test_scenario::return_shared(tokenpolicy);
        };

        // recipient join campaign
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            campaign_management::join_campaign(&mut campaigns, string::utf8(b"Test Campaign"), string::utf8(b"Bob"), test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
        };

        // non campaign owner tries to verify recipients, it fails
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            let mut recipients_list = vector::empty<address>();
            vector::push_back(&mut recipients_list, recipient);

            campaign_management::verify_recipients(&mut campaigns, string::utf8(b"Test Campaign"), recipients_list,
             &mut tokenpolicy, &mut localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
            test_scenario::return_shared(tokenpolicy);
            test_scenario::return_shared(localCoinApp);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::campaign_management::ERecipientLimitReached)]
    fun test_recipients_limit_exceed_fail() {
        // Arrange
        let admin = @0xA;
        let creator = @0xB;
        let recipient1 = @0xC;
        let recipient2 = @0xD;

        let mut scenario = test_scenario::begin(admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))

        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            campaign_management::test_init(test_scenario::ctx(&mut scenario))

        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            local_coin::register_token<SUI>(&localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
        };

        // create campaign
        test_scenario::next_tx(&mut scenario, creator);
        {
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);
            let mut usdcTreasury = test_scenario::take_shared<UsdcTreasury<SUI>>(&scenario);
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);

            let coin = coin::mint_for_testing<SUI>(1_000_000_000, test_scenario::ctx(&mut scenario));
            campaign_management::create_campaign(string::utf8(b"Test Campaign"), string::utf8(b"Descripton"), 1,
             string::utf8(b"Kathmandu"), coin,  &mut localCoinApp, &mut usdcTreasury, & mut campaigns, &mut tokenpolicy, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(usdcTreasury);
            test_scenario::return_shared(campaigns);
            test_scenario::return_shared(tokenpolicy);
        };

        // recipient join campaign
        test_scenario::next_tx(&mut scenario, recipient1);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            campaign_management::join_campaign(&mut campaigns, string::utf8(b"Test Campaign"), string::utf8(b"Bob"), test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
        };

         // another recipient joins campaign
        test_scenario::next_tx(&mut scenario, recipient2);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            campaign_management::join_campaign(&mut campaigns, string::utf8(b"Test Campaign"), string::utf8(b"Jack"), test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
        };

        // verify one recipient
        test_scenario::next_tx(&mut scenario, creator);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            let mut recipients_list = vector::empty<address>();
            vector::push_back(&mut recipients_list, recipient1);

            campaign_management::verify_recipients(&mut campaigns, string::utf8(b"Test Campaign"), recipients_list,
             &mut tokenpolicy, &mut localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
            test_scenario::return_shared(tokenpolicy);
            test_scenario::return_shared(localCoinApp);
        };

        // recipient limit is 1 and, 1 recipient is already verified, again try to verify one more, it fails
        test_scenario::next_tx(&mut scenario, creator);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);
            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            let mut recipients_list = vector::empty<address>();
            vector::push_back(&mut recipients_list, recipient2);

            campaign_management::verify_recipients(&mut campaigns, string::utf8(b"Test Campaign"), recipients_list,
             &mut tokenpolicy, &mut localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
            test_scenario::return_shared(tokenpolicy);
            test_scenario::return_shared(localCoinApp);
        };
        test_scenario::end(scenario);
    }
}