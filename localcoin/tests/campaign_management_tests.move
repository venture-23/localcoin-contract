#[test_only]
module localcoin::campaign_management_tests {
    use localcoin::campaign_management::{Self, Campaigns};
    use localcoin::local_coin::{Self, LOCAL_COIN, LocalCoinApp, UsdcTreasury};
    use localcoin::spendlist_rule::{Self};
    use sui::token::{Self, TokenPolicy, TokenPolicyCap};
    use sui::coin;
    use std::string::{Self};
    use sui::sui::SUI;
    use sui::test_scenario;

    #[test]
    fun test_create_campaign() {
        // Arrange
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

        test_scenario::next_tx(&mut scenario, admin);
        {
            let localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);

            local_coin::register_token<SUI>(&localCoinApp, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
        };

        // Act
        test_scenario::next_tx(&mut scenario, creator);
        {
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);
            let mut usdcTreasury = test_scenario::take_shared<UsdcTreasury<SUI>>(&scenario);
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            let coin = coin::mint_for_testing<SUI>(1_000_000_000, test_scenario::ctx(&mut scenario));
            campaign_management::create_campaign(string::utf8(b"Test Campaign"), string::utf8(b"Descripton"), 2,
             string::utf8(b"Kathmandu"), coin,  &mut localCoinApp, &mut usdcTreasury, & mut campaigns, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(usdcTreasury);
            test_scenario::return_shared(campaigns);
        };

        // Act
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            campaign_management::join_campaign(&mut campaigns, string::utf8(b"Test Campaign"), string::utf8(b"Bob"), test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
        };

        // Assert
        test_scenario::next_tx(&mut scenario, admin);
        {
            let campaigns = test_scenario::take_shared<Campaigns>(&scenario);
            
            assert!(campaign_management::get_unverified_recipients(&campaigns, string::utf8(b"Test Campaign")).get(&recipient) == string::utf8(b"Bob"), 0);
            assert!(campaign_management::get_verified_recipients(&campaigns, string::utf8(b"Test Campaign")).size() == 0, 0);

            test_scenario::return_shared(campaigns);
        };

        // Act
        test_scenario::next_tx(&mut scenario, creator);
        {
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            let mut recipients_list = vector::empty<address>();
            vector::push_back(&mut recipients_list, recipient);

            campaign_management::verify_recipients(&mut campaigns, string::utf8(b"Test Campaign"), recipients_list, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(campaigns);
        };

        // Assert
        test_scenario::next_tx(&mut scenario, admin);
        {
            let campaigns = test_scenario::take_shared<Campaigns>(&scenario);
            
            assert!(campaign_management::get_unverified_recipients(&campaigns, string::utf8(b"Test Campaign")).size() == 0, 0);
            assert!(campaign_management::get_verified_recipients(&campaigns, string::utf8(b"Test Campaign")).get(&recipient) == string::utf8(b"Bob"), 0);

            test_scenario::return_shared(campaigns);
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


        // Act
        test_scenario::next_tx(&mut scenario, creator);
        {
            let mut localCoinApp = test_scenario::take_shared<LocalCoinApp>(&scenario);
            let mut usdcTreasury = test_scenario::take_shared<UsdcTreasury<SUI>>(&scenario);
            let mut campaigns = test_scenario::take_shared<Campaigns>(&scenario);

            let coin = coin::zero(test_scenario::ctx(&mut scenario));
            campaign_management::create_campaign(string::utf8(b"Test Campaign"), string::utf8(b"Descripton"), 2,
             string::utf8(b"Kathmandu"), coin,  &mut localCoinApp, &mut usdcTreasury, &mut campaigns, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(localCoinApp);
            test_scenario::return_shared(usdcTreasury);
            test_scenario::return_shared(campaigns);
        };
        test_scenario::end(scenario);
    }
}