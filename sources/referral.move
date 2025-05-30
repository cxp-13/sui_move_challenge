module referral::referral;

use sui::event;
use sui::table::{Self, Table};

public struct ReferralBook has key, store {
    id: UID,
    referrals: Table<address, address>,
}

public struct ReferralEvent has copy, drop {
    inviter: address,
    invitee: address,
}

public struct Banana has store {
    price: u64,
    name: vector<u8>,
    description: vector<u8>,
}

public struct Apple has store {
    price: u64,
    name: vector<u8>,
    description: vector<u8>,
}

const E_SELF_REFERRAL: u64 = 1;
const E_ALREADY_INVITED: u64 = 2;

fun init(ctx: &mut TxContext) {
    let referral_book = ReferralBook {
        id: object::new(ctx),
        referrals: table::new(ctx),
    };
    transfer::public_share_object(referral_book);
}

#[test_only]
public fun init_for_test(ctx: &mut TxContext): ReferralBook {
    ReferralBook {
        id: object::new(ctx),
        referrals: table::new(ctx),
    }
}

public fun record_referral(referral_book: &mut ReferralBook, inviter: address, invitee: address) {
    assert!(inviter != invitee, E_SELF_REFERRAL);

    assert!(!table::contains(&referral_book.referrals, invitee), E_ALREADY_INVITED);

    table::add(&mut referral_book.referrals, invitee, inviter);

    event::emit(ReferralEvent {
        inviter,
        invitee,
    });
}

public fun get_inviter(referral_book: &ReferralBook, invitee: address): address {
    assert!(table::contains(&referral_book.referrals, invitee), E_ALREADY_INVITED);
    *table::borrow(&referral_book.referrals, invitee)
}
