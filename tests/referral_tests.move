#[test_only]
module referral::referral_tests;

use referral::referral::{Self, ReferralBook, init_for_test};
use std::string;
use sui::test_scenario;
use sui::transfer;
use sui::tx_context;

#[test]
fun test_successful_invitation() {
    // let mut ctx = tx_context::dummy();

    // Test addresses
    let admin = @0xBABE;
    let inviter = @0xA;
    let invitee = @0xB;

    let mut scenario_val = test_scenario::begin(admin);
    let scenario = &mut scenario_val;

    test_scenario::next_tx(scenario, admin);
    {
        init_for_test(test_scenario::ctx(scenario), admin);
    };

    test_scenario::next_tx(scenario, admin);
    {
        let mut referral_book = test_scenario::take_from_address<ReferralBook>(scenario, admin);
        referral::record_referral(&mut referral_book, inviter, invitee);
        let recorded_inviter = referral::get_inviter(&referral_book, invitee);
        assert!(recorded_inviter == inviter, 0);
        test_scenario::return_to_address(admin, referral_book);
    };

    test_scenario::end(scenario_val);
}

#[test]
#[expected_failure(abort_code = 2)]
fun test_double_invitation_fails() {
    // Test addresses
    let admin = @0xBABE;
    let inviter1 = @0xA;
    let inviter2 = @0xC;
    let invitee = @0xB;

    let mut scenario_val = test_scenario::begin(admin);
    let scenario = &mut scenario_val;

    test_scenario::next_tx(scenario, admin);
    {
        init_for_test(test_scenario::ctx(scenario), admin);
    };

    test_scenario::next_tx(scenario, inviter1);
    {
        let mut referral_book = test_scenario::take_from_address<ReferralBook>(scenario, admin);
        referral::record_referral(&mut referral_book, inviter1, invitee);
        test_scenario::return_to_address(admin, referral_book);
    };

    test_scenario::next_tx(scenario, inviter2);
    {
        let mut referral_book = test_scenario::take_from_address<ReferralBook>(scenario, admin);
        referral::record_referral(&mut referral_book, inviter2, invitee); 
        test_scenario::return_to_address(admin, referral_book);
    };

    test_scenario::end(scenario_val);
}

#[test]
#[expected_failure(abort_code = 1)]
fun test_self_invitation_fails() {

    let admin = @0xBABE;
    let user = @0xA;

    let mut scenario_val = test_scenario::begin(admin);
    let scenario = &mut scenario_val;

    test_scenario::next_tx(scenario, admin);
    {
        init_for_test(test_scenario::ctx(scenario), admin);
    };

    test_scenario::next_tx(scenario, user);
    {
        let mut referral_book = test_scenario::take_from_address<ReferralBook>(scenario, admin);
        referral::record_referral(&mut referral_book, user, user); // This should fail
        test_scenario::return_to_address(admin, referral_book);
    };

    test_scenario::end(scenario_val);
}
