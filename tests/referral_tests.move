#[test_only]
module referral::referral_tests;

use referral::referral::{Self, init_for_test};
use sui::test_utils;

#[test]
fun test_successful_invitation() {
    let mut ctx = tx_context::dummy();

    let mut referral_book = init_for_test(&mut ctx);

    // Test addresses
    let inviter = @0xA;
    let invitee = @0xB;

    // Record a referral
    referral::record_referral(&mut referral_book, inviter, invitee);

    // Verify the referral was recorded
    let recorded_inviter = referral::get_inviter(&referral_book, invitee);
    assert!(recorded_inviter == inviter, 0);
    test_utils::destroy(referral_book);
}

#[test]
#[expected_failure(abort_code = 2)]
fun test_double_invitation_fails() {
    let mut ctx = tx_context::dummy();

    // Initialize the referral book
    let mut referral_book = init_for_test(&mut ctx);

    // Test addresses
    let inviter1 = @0xA;
    let inviter2 = @0xC;
    let invitee = @0xB;

    // First referral should succeed
    referral::record_referral(&mut referral_book, inviter1, invitee);

    // Second referral should fail
    referral::record_referral(&mut referral_book, inviter2, invitee);
    test_utils::destroy(referral_book);
}

#[test]
#[expected_failure(abort_code = 1)]
fun test_self_invitation_fails() {
    let mut ctx = tx_context::dummy();

    let mut referral_book = init_for_test(&mut ctx);

    let user = @0xA;

    referral::record_referral(&mut referral_book, user, user);

    test_utils::destroy(referral_book);
}
