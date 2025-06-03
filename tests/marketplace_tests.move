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
    E_INSUFFICIENT_PAYMENT,
    get_user_points,
    create_marketplace_registry_with_multiple_bananas_for_test
};
use referral::referral;
use referral::usdc::USDC;
use std::debug;
use std::string::{Self, String};
use sui::coin;
use sui::test_scenario;
use sui::test_utils::{print, destroy};

#[test]
fun test_purchase_banana_success() {
    let admin = @0xC;
    let grand_inviter = @0xD;
    let inviter = @0xA;
    let invitee = @0xB;

    let mut scenario_val = test_scenario::begin(admin);
    let scenario = &mut scenario_val;

    let banana_price = 1_000_000_000_000; // 1000 USDC
    let initial_usdc_amount: u64 = 2_000_000_000_000; // 2000 USDC
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

        referral::record_referral(&mut referral_book, grand_inviter, inviter);
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

        print(*string::utf8(b"registry items lenght:").as_bytes());
        debug::print(&item_lenght(&registry));

        let payment = coin::split(&mut initial_fund, banana_price, test_scenario::ctx(scenario));

        purchase<USDC, Banana>(&mut registry, banana_id, payment, test_scenario::ctx(scenario));
        assert!(has_purchased(&registry, invitee), 0);

        let inviter_points = get_user_points(&registry, inviter);

        print(*string::utf8(b"inviter_points:").as_bytes());
        debug::print(&inviter_points);

        let grand_points = get_user_points(&registry, grand_inviter);

        print(*string::utf8(b"grand_points:").as_bytes());
        debug::print(&grand_points);

        assert!(inviter_points == 100_000_000_000, 101);
        assert!(grand_points == 10_000_000_000, 102);

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

#[test]
fun test_bulk_purchase_bananas() {
    let admin = @0xC;
    let grand_inviter = @0xD;
    let inviter = @0xA;
    let invitee = @0xB;

    let mut scenario_val = test_scenario::begin(admin);
    let scenario = &mut scenario_val;

    let banana_price = 1_000_000_000_000; 

    // cause TIMEOUT
    // let quantity = 100_000;
    let quantity = 100;

    let total_cost = banana_price * quantity;
    let initial_usdc_amount = total_cost + 1_000_000_000;

    test_scenario::next_tx(scenario, admin);
    {
        let ctx = test_scenario::ctx(scenario);
        referral::init_for_test(ctx, admin);
    };

    let mut banana_id_list: vector<ID>;

    test_scenario::next_tx(scenario, admin);
    {
        let mut referral_book = test_scenario::take_from_address<referral::ReferralBook>(
            scenario,
            admin,
        );

        referral::record_referral(&mut referral_book, grand_inviter, inviter);
        referral::record_referral(&mut referral_book, inviter, invitee);

        // 创建 bananas 和 item_ids
        let mut bananas = vector::empty<Banana>();
        let mut item_ids = vector::empty<ID>();

        let mut i = 0;
        while (i < quantity) {
            let banana = initial_banana(test_scenario::ctx(scenario));

            vector::push_back(&mut item_ids, object::id(&banana));
            vector::push_back(&mut bananas, banana);
            i = i + 1;
        };

        create_marketplace_registry_with_multiple_bananas_for_test<USDC>(
            test_scenario::ctx(scenario),
            referral_book,
            &mut bananas,
            admin,
        );

        banana_id_list = item_ids;
        destroy(bananas);
    };
    test_scenario::next_tx(scenario, invitee);
    {
        let mut fund = coin::mint_for_testing<USDC>(
            initial_usdc_amount,
            test_scenario::ctx(scenario),
        );
        let mut registry = test_scenario::take_from_address<MarketplaceRegistry<USDC>>(
            scenario,
            admin,
        );

        let mut i = 0;
        while (i < quantity) {
            let item_id = vector::remove(&mut banana_id_list, 0);
            let payment = coin::split(&mut fund, banana_price, test_scenario::ctx(scenario));
            purchase<USDC, Banana>(&mut registry, item_id, payment, test_scenario::ctx(scenario));
            i = i + 1;
        };

        assert!(has_purchased(&registry, invitee), 0);

        let inviter_points = get_user_points(&registry, inviter);
        let grand_points = get_user_points(&registry, grand_inviter);

        debug::print(&inviter_points);
        debug::print(&grand_points);

        assert!(inviter_points == 10_000_000_000_000, 101);
        assert!(grand_points == 1_000_000_000_000, 102);

        destroy(registry);
        destroy(fund);
    };

    test_scenario::end(scenario_val);
}
