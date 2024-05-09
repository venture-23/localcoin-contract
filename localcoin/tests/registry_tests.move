#[test_only]
module localcoin::registry_tests {
    use localcoin::registry::{Self, SuperAdminCap, MerchantRegistry};
    use localcoin::local_coin::{Self, LOCAL_COIN};
    use sui::token::{TokenPolicy, TokenPolicyCap};
    use std::string::{Self};
    use sui::test_scenario;


    #[test]
    fun test_merchant_registration() {
        // Arrange
        let admin = @0xA;
        let merchant = @0xB;

        let mut unverified_merchants_list = vector::empty<address>();
        let mut verified_merchants_list = vector::empty<address>();

        let mut scenario = test_scenario::begin(admin);
        {       
            registry::test_init(test_scenario::ctx(&mut scenario));
        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))
        };

        // Act
        test_scenario::next_tx(&mut scenario, merchant);
        {
            let mut merchantRegistry = test_scenario::take_shared<MerchantRegistry>(&scenario);

            registry::merchant_registration(string::utf8(b"Bob"), string::utf8(b"9813214354"), string::utf8(b"Bob Store"), string::utf8(b"Kathmandu"), &mut merchantRegistry, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(merchantRegistry);
        };

        // Assert
        test_scenario::next_tx(&mut scenario, admin);
        {
            let merchantRegistry = test_scenario::take_shared<MerchantRegistry>(&scenario);
            // add merchant to unverified list and assert
            vector::push_back(&mut unverified_merchants_list, merchant);

            assert!(registry::get_unverified_merchants(&merchantRegistry) == unverified_merchants_list, 0);
            assert!(registry::get_verified_merchants(&merchantRegistry) == verified_merchants_list, 0);

            test_scenario::return_shared(merchantRegistry);
        };
        
        // Act
        test_scenario::next_tx(&mut scenario, admin);
        {
            let superAdmin = test_scenario::take_from_sender<SuperAdminCap>(&scenario);
            let mut merchantRegistry = test_scenario::take_shared<MerchantRegistry>(&scenario);

            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let policycap = test_scenario::take_from_sender<TokenPolicyCap<LOCAL_COIN>>(&scenario);

            registry::verify_merchant(&superAdmin, &mut merchantRegistry, &mut tokenpolicy, &policycap, merchant, test_scenario::ctx(&mut scenario));

            test_scenario::return_to_address(admin, superAdmin);
            test_scenario::return_to_address(admin, policycap);

            test_scenario::return_shared(merchantRegistry);
            test_scenario::return_shared(tokenpolicy);
        };

        // Assert
        test_scenario::next_tx(&mut scenario, admin);
        {
            let merchantRegistry = test_scenario::take_shared<MerchantRegistry>(&scenario);
            // remove merchant from unverified and add to verified list and assert
            vector::pop_back(&mut unverified_merchants_list);
            vector::push_back(&mut verified_merchants_list, merchant);

            assert!(registry::get_unverified_merchants(&merchantRegistry) == unverified_merchants_list, 0);
            assert!(registry::get_verified_merchants(&merchantRegistry) == verified_merchants_list, 0);

            test_scenario::return_shared(merchantRegistry);
        };

        // Act
        test_scenario::next_tx(&mut scenario, admin);
        {
            let superAdmin = test_scenario::take_from_sender<SuperAdminCap>(&scenario);
            let mut merchantRegistry = test_scenario::take_shared<MerchantRegistry>(&scenario);

            registry::update_merchant_info(&superAdmin, &mut merchantRegistry, true, merchant, string::utf8(b"Bob"), string::utf8(b"9813214354"), string::utf8(b"Bob new Store"), string::utf8(b"Kathmandu"));

            test_scenario::return_to_address(admin, superAdmin);
            test_scenario::return_shared(merchantRegistry);
        };

        // Assert
        test_scenario::next_tx(&mut scenario, admin);
        {
            let merchantRegistry = test_scenario::take_shared<MerchantRegistry>(&scenario);

            assert!(registry::get_unverified_merchants(&merchantRegistry) == unverified_merchants_list, 0);
            assert!(registry::get_verified_merchants(&merchantRegistry) == verified_merchants_list, 0);

            test_scenario::return_shared(merchantRegistry);
        };

        // Act
        test_scenario::next_tx(&mut scenario, admin);
        {
            let superAdmin = test_scenario::take_from_sender<SuperAdminCap>(&scenario);
            let mut merchantRegistry = test_scenario::take_shared<MerchantRegistry>(&scenario);

            registry::update_merchant_info(&superAdmin, &mut merchantRegistry, false, merchant, string::utf8(b"Bob"), string::utf8(b"9813214354"), string::utf8(b"Bob new Store"), string::utf8(b"Kathmandu"));

            test_scenario::return_to_address(admin, superAdmin);
            test_scenario::return_shared(merchantRegistry);
        };

        // Assert
        test_scenario::next_tx(&mut scenario, admin);
        {
            let merchantRegistry = test_scenario::take_shared<MerchantRegistry>(&scenario);
            // remove merchant from verified and add to unverified list and assert
            // this is because while updating merchant info verified status is made false in above step
            vector::pop_back(&mut verified_merchants_list);
            vector::push_back(&mut unverified_merchants_list, merchant);

            assert!(registry::get_unverified_merchants(&merchantRegistry) == unverified_merchants_list, 0);
            assert!(registry::get_verified_merchants(&merchantRegistry) == verified_merchants_list, 0);

            test_scenario::return_shared(merchantRegistry);
        };
                
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::registry::ERegistrationRequested)]
    fun test_register_merchant_fail() {
        // Arrange
        let admin = @0xA;
        let merchant = @0xB;

        let mut scenario = test_scenario::begin(admin);
        {       
            registry::test_init(test_scenario::ctx(&mut scenario));
        };

        // Act
        test_scenario::next_tx(&mut scenario, merchant);
        {
            let mut merchantRegistry = test_scenario::take_shared<MerchantRegistry>(&scenario);

            registry::merchant_registration(string::utf8(b"Bob"), string::utf8(b"9813214354"), string::utf8(b"Bob Store"), string::utf8(b"Kathmandu"), &mut merchantRegistry, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(merchantRegistry);
        };

        // Act
        test_scenario::next_tx(&mut scenario, merchant);
        {
            let mut merchantRegistry = test_scenario::take_shared<MerchantRegistry>(&scenario);

            registry::merchant_registration(string::utf8(b"Bob"), string::utf8(b"9813214354"), string::utf8(b"Bob Store"), string::utf8(b"Kathmandu"), &mut merchantRegistry, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(merchantRegistry);
        };

        test_scenario::end(scenario);

    }

    #[test, expected_failure(abort_code = localcoin::registry::ENoRegistrationRequest)]
    fun test_verify_merchant_fail() {
        // Arrange
        let admin = @0xA;
        let merchant = @0xB;

        let mut scenario = test_scenario::begin(admin);
        {       
            registry::test_init(test_scenario::ctx(&mut scenario));
        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            local_coin::test_init(test_scenario::ctx(&mut scenario))
        };

        // Act
        test_scenario::next_tx(&mut scenario, admin);
        {
            let superAdmin = test_scenario::take_from_sender<SuperAdminCap>(&scenario);
            let mut merchantRegistry = test_scenario::take_shared<MerchantRegistry>(&scenario);

            let mut tokenpolicy = test_scenario::take_shared<TokenPolicy<LOCAL_COIN>>(&scenario);
            let policycap = test_scenario::take_from_sender<TokenPolicyCap<LOCAL_COIN>>(&scenario);

            registry::verify_merchant(&superAdmin, &mut merchantRegistry, &mut tokenpolicy, &policycap, merchant, test_scenario::ctx(&mut scenario));

            test_scenario::return_to_address(admin, superAdmin);
            test_scenario::return_to_address(admin, policycap);

            test_scenario::return_shared(merchantRegistry);
            test_scenario::return_shared(tokenpolicy);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = localcoin::registry::ENoRegistrationRequest)]
    fun test_update_merchant_info_fail() {
        // Arrange
        let admin = @0xA;
        let merchant = @0xB;

        let mut scenario = test_scenario::begin(admin);
        {       
            registry::test_init(test_scenario::ctx(&mut scenario));
        };

        // Act
        test_scenario::next_tx(&mut scenario, admin);
        {
            let superAdmin = test_scenario::take_from_sender<SuperAdminCap>(&scenario);
            let mut merchantRegistry = test_scenario::take_shared<MerchantRegistry>(&scenario);

            registry::update_merchant_info(&superAdmin, &mut merchantRegistry, false, merchant, string::utf8(b"Bob"), string::utf8(b"9813214354"), string::utf8(b"Bob new Store"), string::utf8(b"Kathmandu"));

            test_scenario::return_to_address(admin, superAdmin);
            test_scenario::return_shared(merchantRegistry);
        };

        test_scenario::end(scenario);
    }

}