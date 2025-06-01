#[test_only]
module referral::marketplace_tests;

use referral::marketplace::{
    create_marketplace_registry_for_test,
    Banana,
    initial_banana,
    purchase,
    has_purchased,
    MarketplaceRegistry,
    item_lenght,
    E_INSUFFICIENT_PAYMENT
};
use referral::referral;
use referral::usdc::USDC;
use std::string::{Self, String};
use sui::coin;
use sui::test_scenario;
use sui::test_utils::{print, destroy};

#[test]
fun test_purchase_banana_success() {
    let admin = @0xC;
    let inviter = @0xA;
    let invitee = @0xB;

    let mut scenario_val = test_scenario::begin(admin);
    let scenario = &mut scenario_val;

    let banana_price = 1_000_000_000_000;
    let initial_usdc_amount: u64 = 2_000_000_000_000;
    let banana_id: ID;

    test_scenario::next_tx(scenario, admin);
    {
        let ctx = test_scenario::ctx(scenario);
        referral::init_for_test(ctx, admin);
    };
    test_scenario::next_tx(scenario, admin);
    {
        let mut referral_book = test_scenario::take_from_address<referral::ReferralBook>(
            scenario,
            admin,
        );
        referral::record_referral(&mut referral_book, inviter, invitee);

        let banana = initial_banana(test_scenario::ctx(scenario));
        banana_id = object::id(&banana);

        let hello: String = string::utf8(b"banana is created");
        print(*hello.as_bytes());

        create_marketplace_registry_for_test<USDC>(
            test_scenario::ctx(scenario),
            referral_book,
            banana,
            admin,
        );
    };

    test_scenario::next_tx(scenario, invitee);
    {
        let mut initial_fund = coin::mint_for_testing<USDC>(
            initial_usdc_amount,
            test_scenario::ctx(scenario),
        );

        let mut registry = test_scenario::take_from_address<MarketplaceRegistry<USDC>>(
            scenario,
            admin,
        );

        let v = vector[item_lenght(&registry)];
        print(v);

        let payment = coin::split(&mut initial_fund, banana_price, test_scenario::ctx(scenario));

        purchase<USDC, Banana>(&mut registry, banana_id, payment, test_scenario::ctx(scenario));

        assert!(has_purchased(&registry, invitee), 0);
        destroy(registry);
        destroy(initial_fund);
    };

    test_scenario::end(scenario_val);
}

#[test]
#[expected_failure(abort_code = referral::E_ALREADY_INVITED)]
fun test_purchase_without_invitation_should_fail() {
    let admin = @0xC;
    let random_user = @0xD;

    let mut scenario_val = test_scenario::begin(admin);
    let scenario = &mut scenario_val;

    let banana_price = 1_000_000_000_000;
    let initial_usdc_amount: u64 = 2_000_000_000_000;
    let banana_id: ID;

    test_scenario::next_tx(scenario, admin);
    {
        let ctx = test_scenario::ctx(scenario);
        referral::init_for_test(ctx, admin);
    };

    test_scenario::next_tx(scenario, admin);
    {
        let referral_book = test_scenario::take_from_address<referral::ReferralBook>(
            scenario,
            admin,
        );
        let banana = initial_banana(test_scenario::ctx(scenario));
        banana_id = object::id(&banana);

        create_marketplace_registry_for_test<USDC>(
            test_scenario::ctx(scenario),
            referral_book,
            banana,
            admin,
        );
    };

    test_scenario::next_tx(scenario, random_user);
    {
        let mut initial_fund = coin::mint_for_testing<USDC>(
            initial_usdc_amount,
            test_scenario::ctx(scenario),
        );

        let mut registry = test_scenario::take_from_address<MarketplaceRegistry<USDC>>(
            scenario,
            admin,
        );

        let payment = coin::split(&mut initial_fund, banana_price, test_scenario::ctx(scenario));

        purchase<USDC, Banana>(&mut registry, banana_id, payment, test_scenario::ctx(scenario));
        destroy(initial_fund);
        destroy(registry);
    };

    test_scenario::end(scenario_val);
}

#[test]
#[expected_failure(abort_code = E_INSUFFICIENT_PAYMENT)]
fun test_purchase_with_insufficient_balance_should_fail() {
    let admin = @0xC;
    let inviter = @0xA;
    let invitee = @0xB;

    let mut scenario_val = test_scenario::begin(admin);
    let scenario = &mut scenario_val;

    let banana_price = 1_000_000_000_000;
    let initial_usdc_amount: u64 = 2_000_000_000_000;
    let banana_id: ID;

    test_scenario::next_tx(scenario, admin);
    {
        let ctx = test_scenario::ctx(scenario);
        referral::init_for_test(ctx, admin);
    };

    test_scenario::next_tx(scenario, admin);
    {
        let mut referral_book = test_scenario::take_from_address<referral::ReferralBook>(
            scenario,
            admin,
        );
        referral::record_referral(&mut referral_book, inviter, invitee);

        let banana = initial_banana(test_scenario::ctx(scenario));
        banana_id = object::id(&banana);

        create_marketplace_registry_for_test<USDC>(
            test_scenario::ctx(scenario),
            referral_book,
            banana,
            admin,
        );
    };

    test_scenario::next_tx(scenario, invitee);
    {
        let mut initial_fund = coin::mint_for_testing<USDC>(
            initial_usdc_amount,
            test_scenario::ctx(scenario),
        );

        let mut registry = test_scenario::take_from_address<MarketplaceRegistry<USDC>>(
            scenario,
            admin,
        );

        let payment = coin::split(
            &mut initial_fund,
            banana_price - 100,
            test_scenario::ctx(scenario),
        );

        purchase<USDC, Banana>(&mut registry, banana_id, payment, test_scenario::ctx(scenario));
        destroy(initial_fund);
        destroy(registry);
    };

    test_scenario::end(scenario_val);
}
